defmodule ComparisonAppWeb.Plugs.SessionId do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    session_id =
      case get_session(conn, :voter_session_id) do
        nil ->
          Ecto.UUID.generate()

        id ->
          id
      end

    conn
    |> put_session(:voter_session_id, session_id)
    |> assign(:session_id, session_id)
  end
end
