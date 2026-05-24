defmodule ComparisonApp.Streamers do
  import Ecto.Query, warn: false

  alias ComparisonApp.Repo
  alias ComparisonApp.Streamers.Streamer

  def list_active do
    from(s in Streamer, where: s.active == true, order_by: [asc: s.id])
    |> Repo.all()
  end

  def list_leaderboard do
    from(s in Streamer,
      where: s.active == true,
      order_by: [desc: s.rating, asc: s.rd, desc: s.comparison_count]
    )
    |> Repo.all()
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
