defmodule ComparisonApp.Ratings.PeriodTest do
  use ExUnit.Case, async: true

  alias ComparisonApp.Ratings.Period

  test "all ranges have labels" do
    for range <- Period.ranges() do
      assert is_binary(Period.label(range))
    end
  end

  test "cutoff ordering" do
    now = ~U[2026-05-24 12:00:00Z]

    assert Period.cutoff(:all_time, now) == nil

    assert Period.cutoff(:last_24_hours, now) ==
             ~U[2026-05-23 12:00:00Z]

    assert Period.cutoff(:last_7_days, now) ==
             ~U[2026-05-17 12:00:00Z]
  end

  test "parse and to_string roundtrip" do
    for range <- Period.ranges() do
      assert Period.parse(Period.to_string(range)) == range
    end
  end
end
