defmodule ComparisonAppWeb.RatingsLive do
  use ComparisonAppWeb, :live_view

  alias ComparisonApp.Ratings
  alias ComparisonApp.Ratings.Period
  alias ComparisonApp.Streamers
  alias ComparisonAppWeb.StreamerComponents

  @max_chart_streamers 5

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(ComparisonApp.PubSub, Ratings.broadcast_topic())
    end

    period = :all_time
    now = DateTime.utc_now()

    socket =
      socket
      |> assign_period(period, now)
      |> assign(selected_ids: MapSet.new(), chart_series: [])

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    period = params |> Map.get("period", "all_time") |> Period.parse()
    now = DateTime.utc_now()

    socket =
      socket
      |> assign_period(period, now)
      |> reload_chart_series()

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="space-y-6 max-w-5xl mx-auto">
        <div class="flex flex-col sm:flex-row sm:items-end sm:justify-between gap-4">
          <div>
            <h1 class="text-2xl font-bold">Live ratings</h1>
            <p class="text-base-content/70 mt-1">
              Top 100 streamers · {@period_label}
              <span class="text-xs block mt-1">
                As of {format_datetime(@now)}
              </span>
            </p>
          </div>
          <div class="flex flex-wrap gap-1">
            <button
              :for={p <- Period.ranges()}
              type="button"
              class={[
                "btn btn-sm",
                if(p == @period, do: "btn-primary", else: "btn-ghost")
              ]}
              phx-click="change_period"
              phx-value-period={Period.to_string(p)}
            >
              {Period.label(p)}
            </button>
          </div>
        </div>

        <div class="grid lg:grid-cols-2 gap-8">
          <div class="overflow-x-auto">
            <p class="text-xs opacity-60 mb-2">
              Click rows to add or remove from the chart (up to {@max_chart_streamers}).
            </p>
            <table class="table table-zebra table-sm">
              <thead>
                <tr>
                  <th>#</th>
                  <th>Streamer</th>
                  <th>Rating</th>
                  <th>RD</th>
                  <th>Votes</th>
                  <th>Last updated</th>
                </tr>
              </thead>
              <tbody id="leaderboard">
                <tr
                  :for={{streamer, idx} <- Enum.with_index(@streamers, 1)}
                  id={"streamer-row-#{streamer.id}"}
                  class={row_class(streamer.id, @selected_ids)}
                  phx-click="toggle_select"
                  phx-value-id={streamer.id}
                >
                  <td>{idx}</td>
                  <td>
                    <div class="flex items-center gap-2">
                      <%= if MapSet.member?(@selected_ids, streamer.id) do %>
                        <span
                          class="w-2.5 h-2.5 rounded-full shrink-0"
                          style={"background-color: #{StreamerComponents.series_color(chart_index(@selected_ids, streamer.id))}"}
                        />
                      <% end %>
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
                  <td class="text-xs whitespace-nowrap">
                    {format_last_updated(streamer)}
                  </td>
                </tr>
              </tbody>
            </table>
            <%= if @streamers == [] do %>
              <p class="text-sm opacity-60 mt-2">No rating activity in this period.</p>
            <% end %>
          </div>

          <div class="card bg-base-200 p-4">
            <div class="flex items-center justify-between gap-2 mb-3">
              <h2 class="font-semibold text-lg">Rating history</h2>
              <%= if MapSet.size(@selected_ids) > 0 do %>
                <button type="button" class="btn btn-ghost btn-xs" phx-click="clear_selection">
                  Clear
                </button>
              <% end %>
            </div>

            <%= if MapSet.size(@selected_ids) == 0 do %>
              <p class="opacity-60 text-sm">
                Select one or more streamers from the table to compare ratings over time.
              </p>
            <% else %>
              <p class="text-sm opacity-70 mb-3">
                Comparing {MapSet.size(@selected_ids)} streamer(s) · {@period_label}
              </p>
              <StreamerComponents.rating_chart
                series={@chart_series}
                width={520}
                height={300}
                show_timestamps={MapSet.size(@selected_ids) == 1}
                show_legend={true}
              />
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
  def handle_event("toggle_select", %{"id" => id}, socket) do
    id = String.to_integer(id)
    selected_ids = socket.assigns.selected_ids

    cond do
      MapSet.member?(selected_ids, id) ->
        selected_ids = MapSet.delete(selected_ids, id)

        {:noreply,
         socket |> assign(selected_ids: selected_ids) |> reload_chart_series()}

      MapSet.size(selected_ids) >= @max_chart_streamers ->
        {:noreply,
         put_flash(
           socket,
           :info,
           "You can compare up to #{@max_chart_streamers} streamers at once."
         )}

      true ->
        selected_ids = MapSet.put(selected_ids, id)

        {:noreply,
         socket |> assign(selected_ids: selected_ids) |> reload_chart_series()}
    end
  end

  def handle_event("clear_selection", _params, socket) do
    {:noreply,
     socket
     |> assign(selected_ids: MapSet.new(), chart_series: [])
     |> clear_flash()}
  end

  def handle_event("change_period", %{"period" => period_str}, socket) do
    {:noreply, push_patch(socket, to: ~p"/ratings?period=#{period_str}")}
  end

  @impl true
  def handle_info({:updated, streamer_ids}, socket) do
    now = DateTime.utc_now()

    affected =
      MapSet.new(streamer_ids)
      |> MapSet.intersection(socket.assigns.selected_ids)
      |> MapSet.size() > 0

    socket = assign_period(socket, socket.assigns.period, now)

    socket =
      if affected do
        reload_chart_series(socket)
      else
        socket
      end

    {:noreply, socket}
  end

  defp assign_period(socket, period, now) do
    cutoff = Period.cutoff(period, now)

    assign(socket,
      period: period,
      period_label: Period.label(period),
      period_cutoff: cutoff,
      now: now,
      max_chart_streamers: @max_chart_streamers,
      streamers: Ratings.list_leaderboard_for_period(period, limit: 100)
    )
  end

  defp reload_chart_series(socket) do
    series =
      socket.assigns.selected_ids
      |> MapSet.to_list()
      |> Enum.sort()
      |> Enum.with_index()
      |> Enum.map(fn {id, idx} ->
        streamer =
          Enum.find(socket.assigns.streamers, &(&1.id == id)) || Streamers.get!(id)

        snapshots =
          Ratings.list_snapshots(id,
            since: socket.assigns.period_cutoff,
            limit: 500
          )

        %{
          label: streamer.display_name,
          snapshots: snapshots,
          color: StreamerComponents.series_color(idx)
        }
      end)

    assign(socket, chart_series: series)
  end

  defp chart_index(selected_ids, streamer_id) do
    selected_ids
    |> MapSet.to_list()
    |> Enum.sort()
    |> Enum.find_index(&(&1 == streamer_id))
    |> Kernel.||(0)
  end

  defp format_datetime(%DateTime{} = dt) do
    Calendar.strftime(dt, "%Y-%m-%d %H:%M UTC")
  end

  defp format_last_updated(%{last_compared_at: %DateTime{} = dt}) do
    format_datetime(dt)
  end

  defp format_last_updated(%{updated_at: %DateTime{} = dt}) do
    format_datetime(dt)
  end

  defp format_last_updated(_), do: "—"

  defp row_class(id, selected_ids) do
    if MapSet.member?(selected_ids, id) do
      "bg-primary/20 cursor-pointer"
    else
      "cursor-pointer hover:bg-base-300"
    end
  end
end
