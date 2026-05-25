defmodule ComparisonAppWeb.StreamerLive do
  use ComparisonAppWeb, :live_view

  alias ComparisonApp.Ratings
  alias ComparisonApp.Ratings.Period
  alias ComparisonApp.Streamers
  alias ComparisonAppWeb.StreamerComponents

  @impl true
  def mount(%{"id" => id}, _params, socket) do
    streamer = Streamers.get!(id)

    {:ok,
     assign(socket,
       streamer: streamer,
       period: :all_time,
       period_label: Period.label(:all_time),
       period_cutoff: nil,
       snapshots: []
     )}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    period = params |> Map.get("period", "all_time") |> Period.parse()
    cutoff = Period.cutoff(period)

    snapshots =
      Ratings.list_snapshots(socket.assigns.streamer.id,
        since: cutoff,
        limit: 500
      )

    {:noreply,
     assign(socket,
       period: period,
       period_label: Period.label(period),
       period_cutoff: cutoff,
       snapshots: snapshots
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="space-y-6 max-w-2xl mx-auto">
        <div class="flex items-center gap-4">
          <img
            src={StreamerComponents.avatar_url(@streamer)}
            class="w-16 h-16 rounded-full"
            alt=""
          />
          <div>
            <h1 class="text-2xl font-bold">{@streamer.display_name}</h1>
            <StreamerComponents.twitch_login streamer={@streamer} />
            <p class="text-xs opacity-60 mt-1">{@period_label}</p>
          </div>
        </div>

        <div class="flex flex-wrap gap-1">
          <button
            :for={p <- Period.ranges()}
            type="button"
            class={[
              "btn btn-xs",
              if(p == @period, do: "btn-primary", else: "btn-ghost")
            ]}
            phx-click="change_period"
            phx-value-period={Period.to_string(p)}
          >
            {Period.label(p)}
          </button>
        </div>

        <dl class="grid grid-cols-3 gap-4 text-center">
          <div class="stat bg-base-200 rounded-lg p-3">
            <dt class="text-xs opacity-60">Rating</dt>
            <dd class="text-xl font-bold">{Float.round(@streamer.rating, 1)}</dd>
          </div>
          <div class="stat bg-base-200 rounded-lg p-3">
            <dt class="text-xs opacity-60">RD</dt>
            <dd class="text-xl font-bold">{Float.round(@streamer.rd, 0)}</dd>
          </div>
          <div class="stat bg-base-200 rounded-lg p-3">
            <dt class="text-xs opacity-60">Comparisons</dt>
            <dd class="text-xl font-bold">{@streamer.comparison_count}</dd>
          </div>
        </dl>

        <div>
          <h2 class="font-semibold mb-2">Rating over time</h2>
          <StreamerComponents.rating_chart
            series={[
              %{
                label: @streamer.display_name,
                snapshots: @snapshots,
                color: StreamerComponents.series_color(0)
              }
            ]}
            width={600}
            height={280}
            show_timestamps={true}
            show_legend={false}
          />
        </div>

        <p class="flex gap-4">
          <.link navigate={~p"/ratings?period=#{Period.to_string(@period)}"} class="link">
            Leaderboard
          </.link>
          <.link navigate={~p"/"} class="link">Compare</.link>
        </p>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("change_period", %{"period" => period_str}, socket) do
    {:noreply,
     push_patch(socket,
       to: ~p"/streamers/#{socket.assigns.streamer.id}?period=#{period_str}"
     )}
  end
end
