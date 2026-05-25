defmodule ComparisonAppWeb.CompareLive do
  use ComparisonAppWeb, :live_view

  alias ComparisonApp.Pairing
  alias ComparisonApp.Ratings.Engine
  alias ComparisonApp.Votes
  alias ComparisonAppWeb.StreamerComponents

  @impl true
  def mount(_params, _session, socket) do
    session_id = socket.assigns.session_id
    ip_hash = socket.assigns.ip_hash
    socket = assign_pair(socket, session_id, ip_hash)
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
            Pick a streamer, or say you don't know them.
            <.link navigate={~p"/faq"} class="link link-hover">How it works</.link>
          </p>
        </div>

        <%= if @error do %>
          <p class="alert alert-warning">{@error}</p>
        <% end %>

        <%= if @left && @right do %>
          <div class="grid md:grid-cols-2 gap-6">
            <StreamerComponents.card streamer={@left} position={:left} />
            <StreamerComponents.card streamer={@right} position={:right} />
          </div>

          <div class="grid grid-cols-1 sm:grid-cols-3 gap-2 max-w-2xl mx-auto w-full">
            <button
              :for={outcome <- [:unknown_left, :unknown_both, :unknown_right]}
              class={[
                "btn btn-outline btn-sm w-full",
                outcome == :unknown_both && "btn-accent"
              ]}
              phx-click="vote"
              phx-value-outcome={outcome}
            >
              {unknown_label(outcome)}
            </button>
          </div>
        <% end %>

        <div class="pt-6 border-t border-base-300/60 flex justify-center">
          <.link
            navigate={~p"/ratings"}
            class="btn btn-outline btn-secondary gap-2 px-6 shadow-sm hover:shadow-md transition-shadow"
          >
            <.icon name="hero-chart-bar" class="size-5 opacity-80" />
            View live ratings
          </.link>
        </div>
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

  defp handle_vote(socket, ui_outcome, position) do
    ui_outcome =
      case {ui_outcome, position} do
        {:liked, :left} -> :liked_left
        {:liked, :right} -> :liked_right
        {other, _} -> other
      end

    %{left: left, right: right, session_id: session_id, ip_hash: ip_hash} = socket.assigns

    outcome = Votes.map_ui_outcome(ui_outcome, left, right)

    case Engine.submit_vote(left, right, outcome, session_id, ip_hash) do
      {:ok, _} ->
        {:noreply, assign_pair(socket, session_id, ip_hash)}

      {:error, %Ecto.Changeset{errors: errors}} ->
        msg = format_changeset_errors(errors)
        {:noreply, put_flash(socket, :error, msg)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not record vote")}
    end
  end

  defp assign_pair(socket, session_id, ip_hash) do
    case Pairing.next_pair(session_id, ip_hash) do
      {:ok, {left, right}} ->
        assign(socket,
          left: left,
          right: right,
          error: nil,
          session_id: session_id
        )

      {:error, :not_enough_streamers} ->
        assign(socket,
          left: nil,
          right: nil,
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
