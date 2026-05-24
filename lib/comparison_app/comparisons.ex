defmodule ComparisonApp.Comparisons do
  import Ecto.Query, warn: false

  alias ComparisonApp.Repo
  alias ComparisonApp.Comparisons.Comparison

  @session_window_hours 24

  def recent_pair_ids(session_id) do
    cutoff = DateTime.utc_now() |> DateTime.add(-@session_window_hours, :hour)

    from(c in Comparison,
      where: c.session_id == ^session_id and c.inserted_at >= ^cutoff,
      select: {c.streamer_a_id, c.streamer_b_id}
    )
    |> Repo.all()
    |> MapSet.new(fn {a, b} -> {a, b} end)
  end

  def already_voted?(session_id, streamer_a_id, streamer_b_id) do
    Repo.exists?(
      from c in Comparison,
        where:
          c.session_id == ^session_id and
            c.streamer_a_id == ^streamer_a_id and
            c.streamer_b_id == ^streamer_b_id
    )
  end
end
