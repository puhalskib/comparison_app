defmodule ComparisonAppWeb.RatingsLive do
  use ComparisonAppWeb, :live_view

  alias ComparisonApp.Ratings
  alias ComparisonApp.Streamers
  alias ComparisonAppWeb.StreamerComponents

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(ComparisonApp.PubSub, Ratings.broadcast_topic())
    end

    socket =
      socket
      |> assign_streamers()
      |> assign(selected: nil, selected_streamer: nil, snapshots: [])

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="space-y-6 max-w-5xl mx-auto">
        <div>
          <h1 class="text-2xl font-bold">Live ratings</h1>
          <p class="text-base-content/70 mt-1">
            Real-time Glicko-2 leaderboard. Click a row for rating history.
          </p>
        </div>

        <div class="grid lg:grid-cols-2 gap-8">
          <div class="overflow-x-auto">
            <table class="table table-zebra table-sm">
              <thead>
                <tr>
                  <th>#</th>
                  <th>Streamer</th>
                  <th>Rating</th>
                  <th>RD</th>
                  <th>Votes</th>
                </tr>
              </thead>
              <tbody id="leaderboard">
                <tr
                  :for={{streamer, idx} <- Enum.with_index(@streamers, 1)}
                  id={"streamer-row-#{streamer.id}"}
                  class={row_class(streamer.id, @selected)}
                  phx-click="select"
                  phx-value-id={streamer.id}
                >
                  <td>{idx}</td>
                  <td>
                    <div class="flex items-center gap-2">
                      <img
                        src={StreamerComponents.avatar_url(streamer)}
                        class="w-8 h-8 rounded-full"
                        alt=""
                      />
                      <span>{streamer.display_name}</span>
                    </div>
                  </td>
                  <td>{Float.round(streamer.rating, 1)}</td>
                  <td>{Float.round(streamer.rd, 0)}</td>
                  <td>{streamer.comparison_count}</td>
                </tr>
              </tbody>
            </table>
          </div>

          <div class="card bg-base-200 p-4">
            <%= if @selected_streamer do %>
              <h2 class="font-semibold text-lg">{@selected_streamer.display_name}</h2>
              <p class="text-sm opacity-70 mb-4">
                Current: {Float.round(@selected_streamer.rating, 1)} (RD {Float.round(
                  @selected_streamer.rd,
                  0
                )})
              </p>
              <StreamerComponents.rating_chart snapshots={@snapshots} />
              <.link
                navigate={~p"/streamers/#{@selected_streamer.id}"}
                class="link link-primary text-sm mt-4 inline-block"
              >
                Full history
              </.link>
            <% else %>
              <p class="opacity-60">Select a streamer to view rating over time.</p>
            <% end %>
          </div>
        </div>

        <p>
          <.link navigate={~p"/"} class="link">Back to compare</.link>
        </p>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("select", %{"id" => id}, socket) do
    id = String.to_integer(id)
    streamer = Enum.find(socket.assigns.streamers, &(&1.id == id))
    snapshots = Ratings.list_snapshots(id)

    {:noreply,
     assign(socket, selected: id, selected_streamer: streamer, snapshots: snapshots)}
  end

  @impl true
  def handle_info({:updated, streamer_ids}, socket) do
    streamers =
      socket.assigns.streamers
      |> Enum.map(fn s ->
        if s.id in streamer_ids do
          Streamers.get!(s.id)
        else
          s
        end
      end)
      |> Enum.sort_by(& &1.rating, :desc)

    socket = assign(socket, streamers: streamers)

    socket =
      if socket.assigns.selected in streamer_ids do
        id = socket.assigns.selected

        assign(socket,
          selected_streamer: Streamers.get!(id),
          snapshots: Ratings.list_snapshots(id)
        )
      else
        socket
      end

    {:noreply, socket}
  end

  defp assign_streamers(socket) do
    assign(socket, streamers: Streamers.list_leaderboard())
  end

  defp row_class(id, id), do: "bg-primary/20 cursor-pointer"
  defp row_class(_id, _selected), do: "cursor-pointer hover:bg-base-300"
end
