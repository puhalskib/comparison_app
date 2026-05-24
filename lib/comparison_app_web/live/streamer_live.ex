defmodule ComparisonAppWeb.StreamerLive do
  use ComparisonAppWeb, :live_view

  alias ComparisonApp.Ratings
  alias ComparisonApp.Streamers
  alias ComparisonAppWeb.StreamerComponents

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    streamer = Streamers.get!(id)
    snapshots = Ratings.list_snapshots(streamer.id, 500)

    {:ok,
     assign(socket,
       streamer: streamer,
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
            <p class="opacity-70">@{@streamer.login}</p>
          </div>
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
          <StreamerComponents.rating_chart snapshots={@snapshots} width={600} height={200} />
        </div>

        <p class="flex gap-4">
          <.link navigate={~p"/ratings"} class="link">Leaderboard</.link>
          <.link navigate={~p"/"} class="link">Compare</.link>
        </p>
      </div>
    </Layouts.app>
    """
  end
end
