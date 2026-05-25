defmodule ComparisonApp.StreamersTest do
  use ComparisonApp.DataCase, async: true

  alias ComparisonApp.Streamers
  alias ComparisonApp.Streamers.Streamer

  defp insert(name, rating, active \\ true) do
    %Streamer{}
    |> Streamer.changeset(%{
      twitch_id: "tw_#{name}",
      login: name,
      display_name: name,
      rating: rating,
      active: active
    })
    |> Repo.insert!()
  end

  test "prune_active_to_top keeps only top N by rating" do
    for {name, rating} <- [{"a", 4000}, {"b", 3000}, {"c", 2000}, {"d", 1000}] do
      insert(name, rating * 1.0)
    end

    :ok = Streamers.prune_active_to_top(2)

    active = Streamers.list_active()
    assert length(active) == 2
    assert Enum.all?(active, & &1.active)
    logins = Enum.map(active, & &1.login) |> MapSet.new()
    assert MapSet.equal?(logins, MapSet.new(["a", "b"]))
  end

  test "list_top_active respects limit" do
    for i <- 1..5, do: insert("s#{i}", i * 100.0)
    assert length(Streamers.list_top_active(3)) == 3
  end
end
