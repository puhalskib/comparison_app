defmodule ComparisonApp.Streamers.AvatarCacheWorker do
  @moduledoc """
  Backfills locally cached avatars for active streamers missing `avatar_path`.
  """

  use Oban.Worker, queue: :default

  alias ComparisonApp.Streamers.AvatarCache

  @impl Oban.Worker
  def perform(_job) do
    AvatarCache.cache_all()
    :ok
  end
end
