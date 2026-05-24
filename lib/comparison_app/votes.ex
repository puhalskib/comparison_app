defmodule ComparisonApp.Votes do
  @moduledoc false

  alias ComparisonApp.Comparisons.Comparison
  alias ComparisonApp.Streamers.Streamer

  @ui_outcomes [:liked_left, :liked_right, :unknown_left, :unknown_right, :unknown_both]

  def ui_outcomes, do: @ui_outcomes

  def map_ui_outcome(ui_outcome, %Streamer{} = left, %Streamer{} = right) do
    {a_id, _b_id} = Comparison.canonical_pair(left, right)
    left_is_a? = left.id == a_id

    case {ui_outcome, left_is_a?} do
      {:liked_left, true} -> :liked_a
      {:liked_left, false} -> :liked_b
      {:liked_right, true} -> :liked_b
      {:liked_right, false} -> :liked_a
      {:unknown_left, true} -> :unknown_a
      {:unknown_left, false} -> :unknown_b
      {:unknown_right, true} -> :unknown_b
      {:unknown_right, false} -> :unknown_a
      {:unknown_both, _} -> :unknown_both
    end
  end
end
