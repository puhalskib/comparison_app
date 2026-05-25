defmodule ComparisonAppWeb.LiveMount do
  import Phoenix.Component, only: [assign: 3]
  import Phoenix.LiveView, only: [get_connect_info: 2]

  alias ComparisonApp.VoterExclusions

  def on_mount(:assign_session_id, _params, session, socket) do
    session_id =
      session["voter_session_id"] ||
        raise "voter_session_id missing from session; ensure SessionId plug runs"

    ip_hash = session["ip_hash"] || ip_hash_from_connect(socket)

    {:cont,
     socket
     |> assign(:session_id, session_id)
     |> assign(:ip_hash, ip_hash)}
  end

  defp ip_hash_from_connect(socket) do
    case get_connect_info(socket, :peer_data) do
      %{address: address} -> VoterExclusions.hash_ip(address)
      _ -> nil
    end
  end
end
