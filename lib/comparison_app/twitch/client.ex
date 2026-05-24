defmodule ComparisonApp.Twitch.Client do
  @moduledoc """
  Minimal Twitch Helix client using Req.
  """

  @helix "https://api.twitch.tv/helix"

  def fetch_app_token do
    client_id = fetch_env!("TWITCH_CLIENT_ID")
    client_secret = fetch_env!("TWITCH_CLIENT_SECRET")

    Req.post!("https://id.twitch.tv/oauth2/token",
      form: [
        client_id: client_id,
        client_secret: client_secret,
        grant_type: "client_credentials"
      ]
    )
    |> Map.get(:body)
    |> then(fn
      %{"access_token" => token} -> {:ok, token}
      _ -> {:error, :token_failed}
    end)
  end

  def get_users([]), do: {:ok, []}

  def get_users(logins) when is_list(logins) do
    logins
    |> Enum.chunk_every(100)
    |> Enum.reduce_while({:ok, []}, fn chunk, {:ok, acc} ->
      with {:ok, token} <- token(),
           {:ok, body} <- helix_get("/users", token, login: chunk) do
        {:cont, {:ok, acc ++ Map.get(body, "data", [])}}
      else
        {:error, _} = err -> {:halt, err}
      end
    end)
  end

  def get_top_streams(first \\ 100) do
    with {:ok, token} <- token(),
         {:ok, body} <- helix_get("/streams", token, first: first) do
      {:ok, Map.get(body, "data", [])}
    end
  end

  defp helix_get(path, token, params) do
    client_id = fetch_env!("TWITCH_CLIENT_ID")

    case Req.get!(@helix <> path,
           params: params,
           headers: %{
             "Client-Id" => client_id,
             "Authorization" => "Bearer #{token}"
           }
         ) do
      %{status: 200, body: body} -> {:ok, body}
      resp -> {:error, {:helix_error, resp.status}}
    end
  rescue
    e -> {:error, e}
  end

  defp token do
    case Application.get_env(:comparison_app, :twitch_access_token) do
      nil -> fetch_app_token()
      token -> {:ok, token}
    end
  end

  defp fetch_env!(key) do
    case System.get_env(key) do
      nil -> raise "missing environment variable #{key}"
      val -> val
    end
  end
end
