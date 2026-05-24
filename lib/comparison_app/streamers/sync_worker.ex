defmodule ComparisonApp.Streamers.SyncWorker do
  @moduledoc """
  Syncs streamers from curated logins and top live Twitch streams.
  """

  use Oban.Worker, queue: :default

  alias ComparisonApp.Streamers
  alias ComparisonApp.Twitch.Client

  @impl Oban.Worker
  def perform(_job) do
    if twitch_configured?() do
      sync_curated()
      sync_top_live()
      :ok
    else
      :ok
    end
  end

  defp sync_curated do
    logins = Application.get_env(:comparison_app, :curated_streamer_logins, [])

    if logins != [] do
      case Client.get_users(logins) do
        {:ok, users} -> upsert_users(users)
        {:error, reason} -> {:error, reason}
      end
    end

    :ok
  end

  defp sync_top_live do
    case Client.get_top_streams(100) do
      {:ok, streams} ->
        logins = streams |> Enum.map(& &1["user_login"]) |> Enum.uniq()
        case Client.get_users(logins) do
          {:ok, users} -> upsert_users(users)
          {:error, _} -> :ok
        end

      {:error, _} ->
        :ok
    end
  end

  defp upsert_users(users) do
    Enum.each(users, fn user ->
      Streamers.upsert_from_twitch(%{
        twitch_id: user["id"],
        login: user["login"],
        display_name: user["display_name"],
        profile_image_url: user["profile_image_url"],
        active: true
      })
    end)
  end

  defp twitch_configured? do
    System.get_env("TWITCH_CLIENT_ID") != nil &&
      System.get_env("TWITCH_CLIENT_SECRET") != nil
  end
end
