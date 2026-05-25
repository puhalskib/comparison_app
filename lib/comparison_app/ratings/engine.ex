defmodule ComparisonApp.Ratings.Engine do
  @moduledoc """
  Applies Glicko-2 updates from comparison outcomes and persists history.
  """

  alias ComparisonApp.Comparisons.Comparison
  alias ComparisonApp.Ratings
  alias ComparisonApp.Ratings.Snapshot
  alias ComparisonApp.Repo
  alias ComparisonApp.Streamers.Streamer
  alias ComparisonApp.VoterExclusions
  alias Ecto.Multi
  alias Phoenix.PubSub

  @tau 0.5

  @spec submit_vote(Streamer.t(), Streamer.t(), atom(), String.t(), String.t() | nil) ::
          {:ok, map()} | {:error, term()}
  def submit_vote(%Streamer{} = left, %Streamer{} = right, outcome, session_id, ip_hash \\ nil) do
    {a_id, b_id} = Comparison.canonical_pair(left, right)
    a = if left.id == a_id, do: left, else: right
    b = if left.id == b_id, do: left, else: right

    {score_a, update_a?, update_b?} = outcome_to_update(outcome)
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    a_after = maybe_rate(a, b, score_a, update_a?)
    b_after = maybe_rate(b, a, 1.0 - score_a, update_b?)

    multi =
      Multi.new()
      |> Multi.insert(:comparison, fn _ ->
        Comparison.changeset(%Comparison{}, %{
          streamer_a_id: a_id,
          streamer_b_id: b_id,
          outcome: outcome,
          session_id: session_id
        })
      end)
      |> maybe_update_streamer(:streamer_a, a, a_after, now)
      |> maybe_update_streamer(:streamer_b, b, b_after, now)
      |> maybe_snapshot(:snapshot_a, :streamer_a, :comparison)
      |> maybe_snapshot(:snapshot_b, :streamer_b, :comparison)
      |> Multi.run(:exclusions, fn _repo, _changes ->
        block_for_unknown(ip_hash, outcome, a, b)
        {:ok, :blocked}
      end)

    case Repo.transaction(multi) do
      {:ok, result} ->
        streamer_ids =
          [:streamer_a, :streamer_b]
          |> Enum.map(&result[&1])
          |> Enum.reject(&is_nil/1)
          |> Enum.map(& &1.id)

        PubSub.broadcast(ComparisonApp.PubSub, Ratings.broadcast_topic(), {:updated, streamer_ids})
        {:ok, result}

      {:error, _step, reason, _changes} ->
        {:error, reason}
    end
  end

  defp maybe_rate(_player, _opponent, _score, false), do: nil

  defp maybe_rate(%Streamer{} = player, %Streamer{} = opponent, score, true) do
    {rating, rd, vol} =
      GlickoRatingSystem.rate(Streamer.rating_tuple(player), [{Streamer.rating_tuple(opponent), score}],
        tau: @tau
      )

    Streamer.apply_rating(player, {rating, rd, vol})
  end

  defp maybe_update_streamer(multi, key, _before, nil, _now), do: Multi.put(multi, key, nil)

  defp maybe_update_streamer(multi, key, before, after_rating, now) do
    attrs = %{
      rating: after_rating.rating,
      rd: after_rating.rd,
      volatility: after_rating.volatility,
      comparison_count: before.comparison_count + 1,
      last_compared_at: now
    }

    Multi.update(multi, key, Streamer.changeset(before, attrs))
  end

  defp maybe_snapshot(multi, snap_key, streamer_key, comparison_key) do
    Multi.run(multi, snap_key, fn repo, changes ->
      case changes[streamer_key] do
        nil ->
          {:ok, nil}

        streamer ->
          %Snapshot{}
          |> Snapshot.changeset(%{
            streamer_id: streamer.id,
            rating: streamer.rating,
            rd: streamer.rd,
            comparison_id: changes[comparison_key].id
          })
          |> repo.insert()
      end
    end)
  end

  def outcome_to_update(:liked_a), do: {1.0, true, true}
  def outcome_to_update(:liked_b), do: {0.0, true, true}
  def outcome_to_update(:unknown_a), do: {0.0, false, true}
  def outcome_to_update(:unknown_b), do: {1.0, true, false}
  def outcome_to_update(:unknown_both), do: {0.5, false, false}

  defp block_for_unknown(nil, _outcome, _a, _b), do: :ok

  defp block_for_unknown(ip_hash, outcome, a, b) do
    ids =
      case outcome do
        :unknown_a -> [a.id]
        :unknown_b -> [b.id]
        :unknown_both -> [a.id, b.id]
        _ -> []
      end

    if ids != [] do
      VoterExclusions.block_streamers(ip_hash, ids)
    end

    :ok
  end

  def streamers_to_block(outcome, a, b) do
    case outcome do
      :unknown_a -> [a.id]
      :unknown_b -> [b.id]
      :unknown_both -> [a.id, b.id]
      _ -> []
    end
  end
end
