defmodule ComparisonAppWeb.CompareLive do
  use ComparisonAppWeb, :live_view

  alias ComparisonApp.Pairing
  alias ComparisonApp.Ratings.Engine
  alias ComparisonApp.Votes
  alias ComparisonAppWeb.StreamerComponents

  @impl true
  def mount(_params, _session, socket) do
    session_id = socket.assigns.session_id
    socket = assign_pair(socket, session_id)
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="space-y-8">
        <div>
          <h1 class="text-2xl font-bold">Who is more likable?</h1>
          <p class="text-base-content/70 mt-1">
            Pick a streamer, or say you don't know them. Votes update Glicko-2 ratings.
          </p>
        </div>

        <%= if @error do %>
          <p class="alert alert-warning">{@error}</p>
        <% end %>

        <%= if @left && @right do %>
          <div class="grid md:grid-cols-2 gap-6">
            <StreamerComponents.card streamer={@left} position={:left} voted={@voted} />
            <StreamerComponents.card streamer={@right} position={:right} voted={@voted} />
          </div>

          <div class="flex flex-wrap gap-2 justify-center">
            <button
              :for={outcome <- [:unknown_left, :unknown_right, :unknown_both]}
              class="btn btn-outline btn-sm"
              phx-click="vote"
              phx-value-outcome={outcome}
              disabled={@voted}
            >
              {unknown_label(outcome)}
            </button>
          </div>

          <%= if @voted do %>
            <div class="text-center">
              <button class="btn btn-primary" phx-click="next_pair">Next pair</button>
            </div>
          <% end %>
        <% end %>

        <p class="text-center">
          <.link navigate={~p"/ratings"} class="link link-primary">View live ratings</.link>
        </p>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("vote", %{"outcome" => outcome_str, "position" => position}, socket)
      when position in ["left", "right"] do
    handle_vote(socket, String.to_existing_atom(outcome_str), String.to_existing_atom(position))
  end

  def handle_event("vote", %{"outcome" => outcome_str}, socket) do
    handle_vote(socket, String.to_existing_atom(outcome_str), nil)
  end

  def handle_event("next_pair", _params, socket) do
    {:noreply, assign_pair(socket, socket.assigns.session_id)}
  end

  defp handle_vote(socket, ui_outcome, position) do
    ui_outcome =
      case {ui_outcome, position} do
        {:liked, :left} -> :liked_left
        {:liked, :right} -> :liked_right
        {other, _} -> other
      end

    %{left: left, right: right, session_id: session_id, voted: false} = socket.assigns

    outcome = Votes.map_ui_outcome(ui_outcome, left, right)

    case Engine.submit_vote(left, right, outcome, session_id) do
      {:ok, _} ->
        {:noreply, assign(socket, voted: true)}

      {:error, %Ecto.Changeset{errors: errors}} ->
        msg = format_changeset_errors(errors)
        {:noreply, put_flash(socket, :error, msg)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not record vote")}
    end
  end

  defp assign_pair(socket, session_id) do
    case Pairing.next_pair(session_id) do
      {:ok, {left, right}} ->
        assign(socket,
          left: left,
          right: right,
          voted: false,
          error: nil,
          session_id: session_id
        )

      {:error, :not_enough_streamers} ->
        assign(socket,
          left: nil,
          right: nil,
          voted: false,
          error: "Need at least two active streamers. Run seeds or Twitch sync.",
          session_id: session_id
        )
    end
  end

  defp unknown_label(:unknown_left), do: "Don't know left"
  defp unknown_label(:unknown_right), do: "Don't know right"
  defp unknown_label(:unknown_both), do: "Don't know both"

  defp format_changeset_errors(errors) do
    errors
    |> Enum.map(fn {field, {msg, _}} -> "#{field} #{msg}" end)
    |> Enum.join(", ")
  end
end
