defmodule ComparisonAppWeb.StreamerComponents do
  use ComparisonAppWeb, :html

  attr :streamer, :map, required: true
  attr :position, :atom, required: true
  attr :voted, :boolean, default: false

  def card(assigns) do
    ~H"""
    <div class="card bg-base-200 shadow-md">
      <div class="card-body items-center text-center gap-4">
        <img
          src={avatar_url(@streamer)}
          alt={@streamer.display_name}
          class="w-24 h-24 rounded-full object-cover bg-base-300"
        />
        <div>
          <h2 class="card-title justify-center">{@streamer.display_name}</h2>
          <p class="text-sm opacity-70">@{@streamer.login}</p>
          <p class="text-xs mt-1">
            Rating {Float.round(@streamer.rating, 1)} · RD {Float.round(@streamer.rd, 0)}
          </p>
        </div>
        <button
          class="btn btn-primary w-full"
          phx-click="vote"
          phx-value-outcome="liked"
          phx-value-position={@position}
          disabled={@voted}
        >
          More likable
        </button>
      </div>
    </div>
    """
  end

  attr :snapshots, :list, required: true
  attr :width, :integer, default: 400
  attr :height, :integer, default: 120

  def rating_chart(assigns) do
    points = chart_points(assigns.snapshots, assigns.width, assigns.height)
    assigns = assign(assigns, :points, points)

    ~H"""
    <%= if @points == "" do %>
      <p class="text-sm opacity-60">No rating history yet.</p>
    <% else %>
      <svg
        viewBox={"0 0 #{@width} #{@height}"}
        class="w-full max-w-lg bg-base-200 rounded-lg"
        preserveAspectRatio="none"
      >
        <polyline
          fill="none"
          stroke="currentColor"
          stroke-width="2"
          points={@points}
          class="text-primary"
        />
      </svg>
    <% end %>
    """
  end

  def avatar_url(%{profile_image_url: url}) when is_binary(url) and url != "", do: url
  def avatar_url(%{login: login}), do: "https://unavatar.io/twitch/#{login}"

  defp chart_points([], _w, _h), do: ""

  defp chart_points(snapshots, width, height) do
    ratings = Enum.map(snapshots, & &1.rating)
    min_r = Enum.min(ratings)
    max_r = Enum.max(ratings)
    range = max(max_r - min_r, 1.0)
    pad = 8
    plot_h = height - 2 * pad
    plot_w = width - 2 * pad
    n = length(snapshots)

    snapshots
    |> Enum.with_index()
    |> Enum.map(fn {snap, i} ->
      x = pad + if(n == 1, do: plot_w / 2, else: i / (n - 1) * plot_w)
      y = pad + plot_h - (snap.rating - min_r) / range * plot_h
      "#{Float.round(x, 1)},#{Float.round(y, 1)}"
    end)
    |> Enum.join(" ")
  end
end
