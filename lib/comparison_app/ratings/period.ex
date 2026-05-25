defmodule ComparisonApp.Ratings.Period do
  @moduledoc """
  Time ranges for filtering ratings views and leaderboards.
  """

  @ranges [
    :all_time,
    :last_year,
    :last_6_months,
    :last_month,
    :last_7_days,
    :last_24_hours
  ]

  def ranges, do: @ranges

  def valid?(period) when period in @ranges, do: true
  def valid?(_), do: false

  def parse("all_time"), do: :all_time
  def parse("last_year"), do: :last_year
  def parse("last_6_months"), do: :last_6_months
  def parse("last_month"), do: :last_month
  def parse("last_7_days"), do: :last_7_days
  def parse("last_24_hours"), do: :last_24_hours
  def parse(_), do: :all_time

  def to_string(:all_time), do: "all_time"
  def to_string(:last_year), do: "last_year"
  def to_string(:last_6_months), do: "last_6_months"
  def to_string(:last_month), do: "last_month"
  def to_string(:last_7_days), do: "last_7_days"
  def to_string(:last_24_hours), do: "last_24_hours"

  def label(:all_time), do: "All time"
  def label(:last_year), do: "Last year"
  def label(:last_6_months), do: "Last 6 months"
  def label(:last_month), do: "Last month"
  def label(:last_7_days), do: "Last 7 days"
  def label(:last_24_hours), do: "Last 24 hours"

  def cutoff(period, now \\ DateTime.utc_now())

  def cutoff(:all_time, _now), do: nil

  def cutoff(:last_24_hours, now),
    do: DateTime.add(now, -24, :hour) |> DateTime.truncate(:second)

  def cutoff(:last_7_days, now),
    do: DateTime.add(now, -7, :day) |> DateTime.truncate(:second)

  def cutoff(:last_month, now),
    do: DateTime.add(now, -30, :day) |> DateTime.truncate(:second)

  def cutoff(:last_6_months, now),
    do: DateTime.add(now, -180, :day) |> DateTime.truncate(:second)

  def cutoff(:last_year, now),
    do: DateTime.add(now, -365, :day) |> DateTime.truncate(:second)
end
