defmodule ComparisonApp.Streamers do
  import Ecto.Query, warn: false

  alias ComparisonApp.Repo
  alias ComparisonApp.Streamers.Streamer

  def list_active do
    from(s in Streamer, where: s.active == true, order_by: [asc: s.id])
    |> Repo.all()
  end

  def list_top_active(limit \\ 100) do
    from(s in Streamer,
      where: s.active == true,
      order_by: [desc: s.rating, asc: s.rd],
      limit: ^limit
    )
    |> Repo.all()
  end

  def list_leaderboard do
    list_top_active(100)
  end

  def prune_active_to_top(limit \\ 100) do
    top_ids =
      from(s in Streamer,
        order_by: [desc: s.rating, asc: s.rd, asc: s.id],
        limit: ^limit,
        select: s.id
      )
      |> Repo.all()

    now = DateTime.utc_now() |> DateTime.truncate(:second)
    set_active = [active: true, updated_at: now]
    set_inactive = [active: false, updated_at: now]

    from(s in Streamer, where: s.id in ^top_ids)
    |> Repo.update_all(set: set_active)

    from(s in Streamer, where: s.id not in ^top_ids)
    |> Repo.update_all(set: set_inactive)

    :ok
  end

  def get!(id), do: Repo.get!(Streamer, id)
  def get(id), do: Repo.get(Streamer, id)

  def get_by_twitch_id(twitch_id) do
    Repo.get_by(Streamer, twitch_id: twitch_id)
  end

  def upsert_from_twitch(attrs) do
    case get_by_twitch_id(attrs.twitch_id) do
      nil ->
        %Streamer{}
        |> Streamer.changeset(attrs)
        |> Repo.insert()

      streamer ->
        streamer
        |> Streamer.changeset(Map.take(attrs, [:login, :display_name, :profile_image_url, :active]))
        |> Repo.update()
    end
  end

  def change(%Streamer{} = streamer, attrs \\ %{}) do
    Streamer.changeset(streamer, attrs)
  end
end
