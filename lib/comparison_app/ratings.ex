defmodule ComparisonApp.Ratings do
  import Ecto.Query, warn: false

  alias ComparisonApp.Repo
  alias ComparisonApp.Ratings.Snapshot

  def list_snapshots(streamer_id, limit \\ 100) do
    from(s in Snapshot,
      where: s.streamer_id == ^streamer_id,
      order_by: [asc: s.inserted_at],
      limit: ^limit
    )
    |> Repo.all()
  end

  def broadcast_topic, do: "ratings"
end
