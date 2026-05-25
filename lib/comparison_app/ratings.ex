defmodule ComparisonApp.Ratings do
  import Ecto.Query, warn: false

  alias ComparisonApp.Ratings.Period
  alias ComparisonApp.Ratings.Snapshot
  alias ComparisonApp.Repo
  alias ComparisonApp.Streamers.Streamer

  def broadcast_topic, do: "ratings"

  def list_snapshots(streamer_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 500)
    since = Keyword.get(opts, :since)

    query =
      from(s in Snapshot,
        where: s.streamer_id == ^streamer_id,
        order_by: [asc: s.inserted_at],
        limit: ^limit
      )

    query =
      if since do
        from(s in query, where: s.inserted_at >= ^since)
      else
        query
      end

    Repo.all(query)
  end

  def list_leaderboard_for_period(period, opts \\ []) do
    limit = Keyword.get(opts, :limit, 100)
    cutoff = Period.cutoff(period)

    if cutoff do
      leaderboard_from_snapshots(cutoff, limit)
    else
      from(s in Streamer,
        where: s.active == true,
        order_by: [desc: s.rating, asc: s.rd, desc: s.comparison_count],
        limit: ^limit
      )
      |> Repo.all()
    end
  end

  defp leaderboard_from_snapshots(cutoff, limit) do
    latest =
      from(s in Snapshot,
        where: s.inserted_at >= ^cutoff,
        distinct: [s.streamer_id],
        order_by: [asc: s.streamer_id, desc: s.inserted_at],
        select: %{
          streamer_id: s.streamer_id,
          rating: s.rating,
          rd: s.rd,
          snapshot_at: s.inserted_at
        }
      )

    from(st in Streamer,
      inner_join: snap in subquery(latest),
      on: snap.streamer_id == st.id,
      where: st.active == true,
      order_by: [desc: snap.rating, asc: snap.rd],
      limit: ^limit,
      select: {st, snap}
    )
    |> Repo.all()
    |> Enum.map(fn {st, snap} ->
      %{st | rating: snap.rating, rd: snap.rd}
    end)
  end
end
