defmodule ComparisonAppWeb.Plugs.ClientIp do
  import Plug.Conn

  alias ComparisonApp.VoterExclusions

  def init(opts), do: opts

  def call(conn, _opts) do
    ip_hash = VoterExclusions.hash_ip(conn.remote_ip)

    conn
    |> put_session(:ip_hash, ip_hash)
    |> assign(:ip_hash, ip_hash)
  end
end
