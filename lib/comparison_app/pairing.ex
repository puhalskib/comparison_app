defmodule ComparisonApp.Pairing do
  @moduledoc """
  Selects pairs of streamers for comparison with exploration/exploitation mix.
  """

  alias ComparisonApp.Comparisons
  alias ComparisonApp.Streamers
  alias ComparisonApp.Streamers.Streamer
  alias ComparisonApp.VoterExclusions

  @exploration_weight 0.7
  @exploration_comparison_cap 50
  @min_active_streamers 2
  @pool_limit 100

  @spec next_pair(String.t(), String.t() | nil) ::
          {:ok, {Streamer.t(), Streamer.t()}} | {:error, :not_enough_streamers}
  def next_pair(session_id, ip_hash \\ nil) do
    streamers = Streamers.list_top_active(@pool_limit)
    blocked = VoterExclusions.blocked_streamer_ids(ip_hash)

    streamers =
      Enum.reject(streamers, fn s -> MapSet.member?(blocked, s.id) end)

    if length(streamers) < @min_active_streamers do
      {:error, :not_enough_streamers}
    else
      excluded = Comparisons.recent_pair_ids(session_id)
      pick_pair(streamers, excluded, :rand.uniform() <= @exploration_weight)
    end
  end

  defp pick_pair(streamers, excluded, true) do
    exploration_pair(streamers, excluded)
    |> or_else(fn -> exploitation_pair(streamers, excluded) end)
    |> or_else(fn -> random_pair(streamers) end)
  end

  defp pick_pair(streamers, excluded, false) do
    exploitation_pair(streamers, excluded)
    |> or_else(fn -> exploration_pair(streamers, excluded) end)
    |> or_else(fn -> random_pair(streamers) end)
  end

  defp or_else({:ok, _} = ok, _fun), do: ok
  defp or_else(nil, fun), do: fun.()
  defp or_else({:error, _} = err, _fun), do: err

  defp exploration_pair(streamers, excluded) do
    candidates =
      Enum.filter(streamers, fn s ->
        s.comparison_count < @exploration_comparison_cap
      end)

    pick_from_pool(candidates, excluded)
    |> or_else(fn -> pick_from_pool(streamers, excluded) end)
  end

  defp exploitation_pair(streamers, excluded) do
    sorted = Enum.sort_by(streamers, & &1.rating)

    pairs =
      for {a, idx_a} <- Enum.with_index(sorted),
          {b, idx_b} <- Enum.with_index(sorted),
          idx_a < idx_b,
          abs(a.rating - b.rating) < 200,
          pair_key(a, b) not in excluded,
          do: {a, b, a.rd + b.rd}

    case pairs do
      [] ->
        nil

      pairs ->
        {a, b, _} = Enum.max_by(pairs, fn {_a, _b, score} -> score end)
        {:ok, {a, b}}
    end
  end

  defp random_pair(streamers) do
    case pick_from_pool(streamers, MapSet.new()) do
      nil -> {:error, :not_enough_streamers}
      {:ok, pair} -> {:ok, pair}
    end
  end

  defp pick_from_pool([], _excluded), do: nil

  defp pick_from_pool(streamers, excluded) do
    shuffled = Enum.shuffle(streamers)

    case find_pair(shuffled, excluded) do
      nil -> nil
      pair -> {:ok, pair}
    end
  end

  defp find_pair([s | rest], excluded) do
    case Enum.find(rest, fn other ->
           s.id != other.id and pair_key(s, other) not in excluded
         end) do
      nil -> find_pair(rest, excluded)
      other -> {s, other}
    end
  end

  defp find_pair([], _excluded), do: nil

  defp pair_key(%Streamer{id: a}, %Streamer{id: b}) when a < b, do: {a, b}
  defp pair_key(a, b), do: pair_key(b, a)
end
