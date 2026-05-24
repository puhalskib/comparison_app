defmodule ComparisonAppWeb.LiveMount do
  import Phoenix.Component, only: [assign: 3]

  def on_mount(:assign_session_id, _params, session, socket) do
    session_id =
      session["voter_session_id"] ||
        raise "voter_session_id missing from session; ensure SessionId plug runs"

    {:cont, assign(socket, :session_id, session_id)}
  end
end
