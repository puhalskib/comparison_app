defmodule Mix.Tasks.Streamers.CacheAvatars do
  @shortdoc "Download and cache streamer avatars locally"
  @moduledoc """
  Fetches profile images (from Twitch when needed) and stores them under
  `priv/uploads/avatars` for local serving.

      mix streamers.cache_avatars
  """

  use Mix.Task

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("app.start")

    ComparisonApp.Streamers.AvatarCache.cache_all!()
    Mix.shell().info("Avatar cache complete.")
  end
end
