defmodule ComparisonApp.Streamers.AvatarCache do
  @moduledoc """
  Downloads streamer profile images and stores them under `priv/uploads/avatars`
  so the app can serve them locally instead of third-party avatar services.
  """

  import Ecto.Query, warn: false

  alias ComparisonApp.Repo
  alias ComparisonApp.Streamers.Streamer
  alias ComparisonApp.Twitch.Client

  @public_prefix "/uploads/avatars"

  def storage_dir do
    Application.get_env(:comparison_app, :avatar_storage_dir) ||
      Path.join([:code.priv_dir(:comparison_app), "uploads", "avatars"])
  end

  def cache(%Streamer{} = streamer) do
    streamer = ensure_profile_image_url(streamer)

    case streamer.profile_image_url do
      url when is_binary(url) and url != "" ->
        download_and_store(streamer, url)

      _ ->
        :skipped
    end
  end

  def cache_all do
    from(s in Streamer, where: s.active == true and (is_nil(s.avatar_path) or s.avatar_path == ""))
    |> Repo.all()
    |> Enum.map(&cache/1)
  end

  def cache_all! do
    cache_all()
    :ok
  end

  defp ensure_profile_image_url(%Streamer{profile_image_url: url} = streamer)
       when is_binary(url) and url != "" do
    streamer
  end

  defp ensure_profile_image_url(%Streamer{login: login} = streamer) do
    if twitch_configured?() do
      case Client.get_users([login]) do
        {:ok, [user | _]} ->
          url = user["profile_image_url"]

          if is_binary(url) and url != "" do
            {:ok, updated} =
              streamer
              |> Streamer.changeset(%{profile_image_url: url})
              |> Repo.update()

            updated
          else
            streamer
          end

        _ ->
          streamer
      end
    else
      streamer
    end
  end

  defp download_and_store(%Streamer{} = streamer, url) do
    case Req.get(url, redirect: true, max_redirects: 5) do
      {:ok, %{status: status, body: body, headers: headers}} when status in 200..299 ->
        ext = extension(headers, url)
        filename = "#{streamer.twitch_id}#{ext}"
        dir = storage_dir()
        File.mkdir_p!(dir)
        path = Path.join(dir, filename)
        File.write!(path, body)

        public_path = "#{@public_prefix}/#{filename}"
        set_avatar_path(streamer, public_path)

      {:ok, %{status: status}} ->
        {:error, {:http_status, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp set_avatar_path(%Streamer{} = streamer, public_path) do
    streamer
    |> Streamer.changeset(%{avatar_path: public_path})
    |> Repo.update()
  end

  defp extension(headers, url) do
    content_type =
      headers
      |> List.keyfind("content-type", 0)
      |> case do
        {_, value} -> value |> List.first() |> String.split(";") |> hd()
        _ -> nil
      end

    case content_type do
      "image/jpeg" -> ".jpg"
      "image/png" -> ".png"
      "image/gif" -> ".gif"
      "image/webp" -> ".webp"
      _ -> ext_from_url(url)
    end
  end

  defp ext_from_url(url) do
    url
    |> URI.parse()
    |> Map.get(:path, "")
    |> Path.extname()
    |> case do
      ext when ext in [".jpg", ".jpeg", ".png", ".gif", ".webp"] -> ext
      ".jpeg" -> ".jpg"
      _ -> ".jpg"
    end
  end

  defp twitch_configured? do
    System.get_env("TWITCH_CLIENT_ID") != nil &&
      System.get_env("TWITCH_CLIENT_SECRET") != nil
  end
end
