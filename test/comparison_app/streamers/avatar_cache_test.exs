defmodule ComparisonApp.Streamers.AvatarCacheTest do
  use ComparisonApp.DataCase, async: true

  alias ComparisonAppWeb.StreamerComponents

  test "avatar_url prefers cached path" do
    assert StreamerComponents.avatar_url(%{avatar_path: "/uploads/avatars/1.jpg"}) ==
             "/uploads/avatars/1.jpg"
  end

  test "avatar_url falls back to twitch profile url" do
    url = "https://static-cdn.jtvnw.net/example.png"

    assert StreamerComponents.avatar_url(%{profile_image_url: url}) == url
  end

  test "avatar_url uses default when no cache or twitch url" do
    assert StreamerComponents.avatar_url(%{login: "nobody"}) ==
             "/images/default-streamer.svg"
  end

  test "twitch_url builds profile link from login" do
    assert StreamerComponents.twitch_url(%{login: "ninja"}) == "https://www.twitch.tv/ninja"
  end
end
