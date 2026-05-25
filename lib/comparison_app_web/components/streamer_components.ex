defmodule ComparisonAppWeb.StreamerComponents do
  use ComparisonAppWeb, :html

  @chart_colors [
    "#6366f1",
    "#f97316",
    "#10b981",
    "#ec4899",
    "#eab308",
    "#06b6d4",
    "#a855f7",
    "#ef4444"
  ]

  @margin_left 52
  @margin_right 16
  @margin_top 20
  @margin_bottom 44

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
          <.twitch_login streamer={@streamer} class="text-sm" />
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

  attr :series, :list, default: []
  attr :snapshots, :list, default: []
  attr :width, :integer, default: 520
  attr :height, :integer, default: 280
  attr :show_timestamps, :boolean, default: false
  attr :show_legend, :boolean, default: true

  def rating_chart(assigns) do
    series = normalize_series(assigns)
    chart = build_chart(series, assigns.width, assigns.height)
    width = assigns.width
    height = assigns.height

    assigns =
      assigns
      |> assign(:series, series)
      |> assign(:margin_left, @margin_left)
      |> assign(:margin_top, @margin_top)
      |> assign(:margin_bottom, @margin_bottom)
      |> assign(:chart_empty?, chart.empty?)
      |> assign(:chart_lines, chart.lines)
      |> assign(:chart_y_ticks, chart.y_ticks)
      |> assign(:chart_x_ticks, chart.x_ticks)
      |> assign(:plot_right_x, plot_right(width))
      |> assign(:plot_bottom_y, plot_bottom(height))
      |> assign(:chart_center_x, (@margin_left + plot_right(width)) / 2)

    ~H"""
    <%= if @chart_empty? do %>
      <p class="text-sm opacity-60">No rating changes in this period.</p>
    <% else %>
      <figure class="w-full">
        <svg
          viewBox={"0 0 #{@width} #{@height}"}
          class="w-full max-w-2xl bg-base-200 rounded-lg"
          preserveAspectRatio="xMidYMid meet"
          role="img"
          aria-label="Rating history chart"
        >
          <%!-- Y axis title --%>
          <text
            x="14"
            y={@height / 2}
            text-anchor="middle"
            transform={"rotate(-90 14 #{@height / 2})"}
            class="fill-base-content text-[11px] font-medium"
          >
            Rating
          </text>

          <%!-- X axis title --%>
          <text
            x={@chart_center_x}
            y={@height - 6}
            text-anchor="middle"
            class="fill-base-content text-[11px] font-medium"
          >
            Time (UTC)
          </text>

          <%!-- Grid and Y ticks --%>
          <line
            :for={tick <- @chart_y_ticks}
            x1={@margin_left}
            y1={tick.y}
            x2={@plot_right_x}
            y2={tick.y}
            class="stroke-base-content/10"
            stroke-width="1"
          />
          <text
            :for={tick <- @chart_y_ticks}
            x={@margin_left - 6}
            y={tick.y}
            text-anchor="end"
            dominant-baseline="middle"
            class="fill-base-content/70 text-[10px] font-mono"
          >
            {tick.label}
          </text>

          <%!-- X ticks --%>
          <text
            :for={tick <- @chart_x_ticks}
            x={tick.x}
            y={@plot_bottom_y + 14}
            text-anchor="middle"
            class="fill-base-content/70 text-[9px] font-mono"
          >
            {tick.label}
          </text>

          <%!-- Axes --%>
          <line
            x1={@margin_left}
            y1={@margin_top}
            x2={@margin_left}
            y2={@plot_bottom_y}
            class="stroke-base-content/40"
            stroke-width="1.5"
          />
          <line
            x1={@margin_left}
            y1={@plot_bottom_y}
            x2={@plot_right_x}
            y2={@plot_bottom_y}
            class="stroke-base-content/40"
            stroke-width="1.5"
          />

          <%!-- Series lines --%>
          <polyline
            :for={line <- @chart_lines}
            fill="none"
            stroke={line.color}
            stroke-width="2.5"
            stroke-linejoin="round"
            stroke-linecap="round"
            points={line.points}
            opacity="0.9"
          />
        </svg>

        <%= if @show_legend && length(@chart_lines) > 0 do %>
          <ul class="flex flex-wrap gap-3 mt-2 text-xs">
            <li :for={line <- @chart_lines} class="flex items-center gap-1.5">
              <span class="inline-block w-3 h-3 rounded-full" style={"background-color: #{line.color}"} />
              <span>{line.label}</span>
            </li>
          </ul>
        <% end %>
      </figure>

      <%= if @show_timestamps && length(@series) == 1 do %>
        <ul class="mt-3 space-y-1 max-h-48 overflow-y-auto text-xs font-mono">
          <li
            :for={snap <- Enum.take(hd(@series).snapshots, -20)}
            class="flex justify-between gap-2"
          >
            <span class="opacity-70">{format_snapshot_time(snap.inserted_at)}</span>
            <span>{Float.round(snap.rating, 1)}</span>
          </li>
        </ul>
      <% end %>
    <% end %>
    """
  end

  defp plot_right(width), do: width - @margin_right
  defp plot_bottom(height), do: height - @margin_bottom

  def series_color(index), do: Enum.at(@chart_colors, rem(index, length(@chart_colors)))

  attr :streamer, :map, required: true
  attr :class, :string, default: nil

  def twitch_login(assigns) do
    ~H"""
    <p class={["opacity-70", @class]}>
      <a
        href={twitch_url(@streamer)}
        target="_blank"
        rel="noopener noreferrer"
        class="link link-hover"
      >
        @{@streamer.login}
      </a>
    </p>
    """
  end

  def twitch_url(%{login: login}) when is_binary(login) do
    "https://www.twitch.tv/#{URI.encode(login)}"
  end

  def avatar_url(%{avatar_path: path}) when is_binary(path) and path != "", do: path
  def avatar_url(%{profile_image_url: url}) when is_binary(url) and url != "", do: url
  def avatar_url(_), do: ~p"/images/default-streamer.svg"

  defp format_snapshot_time(%DateTime{} = dt) do
    Calendar.strftime(dt, "%Y-%m-%d %H:%M")
  end

  defp normalize_series(assigns) do
    cond do
      assigns.series != [] ->
        Enum.map(assigns.series, fn s ->
          %{label: s[:label] || s["label"] || "Streamer", snapshots: s[:snapshots] || s["snapshots"] || [], color: s[:color] || s["color"]}
        end)

      assigns.snapshots != [] ->
        [%{label: "Rating", snapshots: assigns.snapshots, color: series_color(0)}]

      true ->
        []
    end
    |> Enum.reject(&(length(&1.snapshots) == 0))
  end

  defp build_chart(series, width, height) do
    all_snapshots = Enum.flat_map(series, & &1.snapshots)

    if all_snapshots == [] do
      %{empty?: true, lines: [], y_ticks: [], x_ticks: []}
    else
      min_t = all_snapshots |> Enum.min_by(& &1.inserted_at, DateTime) |> Map.fetch!(:inserted_at)
      max_t = all_snapshots |> Enum.max_by(& &1.inserted_at, DateTime) |> Map.fetch!(:inserted_at)

      ratings = Enum.map(all_snapshots, & &1.rating)
      min_r = Enum.min(ratings)
      max_r = Enum.max(ratings)
      pad_r = max((max_r - min_r) * 0.05, 5.0)
      min_r = min_r - pad_r
      max_r = max_r + pad_r

      plot_w = plot_right(width) - @margin_left
      plot_h = plot_bottom(height) - @margin_top

      lines =
        Enum.map(series, fn %{label: label, snapshots: snapshots, color: color} ->
          sorted = Enum.sort_by(snapshots, & &1.inserted_at, DateTime)

          points =
            Enum.map_join(sorted, " ", fn snap ->
              {x, y} = coords(snap, min_t, max_t, min_r, max_r, plot_w, plot_h, width, height)
              "#{x},#{y}"
            end)

          %{label: label, color: color, points: points}
        end)
        |> Enum.reject(&(&1.points == ""))

      %{
        empty?: lines == [],
        lines: lines,
        y_ticks: y_ticks(min_r, max_r, height),
        x_ticks: x_ticks(min_t, max_t, width)
      }
    end
  end

  defp coords(snap, min_t, max_t, min_r, max_r, plot_w, plot_h, _width, _height) do
    t_range = max(DateTime.diff(max_t, min_t, :second), 1)
    r_range = max(max_r - min_r, 1.0)

    t_offset = DateTime.diff(snap.inserted_at, min_t, :second)
    x = @margin_left + t_offset / t_range * plot_w
    y = @margin_top + plot_h - (snap.rating - min_r) / r_range * plot_h

    {Float.round(x, 1), Float.round(y, 1)}
  end

  defp y_ticks(min_r, max_r, height) do
    steps = 5

    for i <- 0..steps do
      ratio = i / steps
      value = max_r - ratio * (max_r - min_r)
      y = @margin_top + ratio * (plot_bottom(height) - @margin_top)

      %{y: Float.round(y, 1), label: Float.round(value, 0) |> to_string()}
    end
  end

  defp x_ticks(min_t, max_t, width) do
    steps = 4
    plot_w = plot_right(width) - @margin_left
    t_range = max(DateTime.diff(max_t, min_t, :second), 1)

    for i <- 0..steps do
      ratio = i / steps
      offset = trunc(ratio * t_range)
      dt = DateTime.add(min_t, offset, :second)
      x = @margin_left + ratio * plot_w

      %{x: Float.round(x, 1), label: format_axis_time(dt, min_t, max_t)}
    end
  end

  defp format_axis_time(dt, min_t, max_t) do
    span_days = DateTime.diff(max_t, min_t, :day)

    cond do
      span_days >= 30 -> Calendar.strftime(dt, "%b %d")
      span_days >= 2 -> Calendar.strftime(dt, "%m/%d %H:%M")
      true -> Calendar.strftime(dt, "%H:%M")
    end
  end
end
