defmodule ComparisonApp.PairingTest do
  use ComparisonApp.DataCase, async: true

  alias ComparisonApp.Comparisons.Comparison
  alias ComparisonApp.Pairing
  alias ComparisonApp.Streamers.Streamer

  defp insert_streamer(login) do
    %Streamer{}
    |> Streamer.changeset(%{
      twitch_id: "tw_#{login}",
      login: login,
      display_name: login
    })
    |> Repo.insert!()
  end

  describe "next_pair/1" do
    test "returns error when fewer than two active streamers" do
      insert_streamer("solo")
      assert {:error, :not_enough_streamers} = Pairing.next_pair("session-1")
    end

    test "returns two distinct streamers" do
      insert_streamer("one")
      insert_streamer("two")
      assert {:ok, {a, b}} = Pairing.next_pair("session-2")
      assert a.id != b.id
    end

    test "excludes pairs already voted on in session" do
      s1 = insert_streamer("a")
      s2 = insert_streamer("b")
      s3 = insert_streamer("c")

      {a_id, b_id} = Comparison.canonical_pair(s1, s2)

      %Comparison{}
      |> Comparison.changeset(%{
        streamer_a_id: a_id,
        streamer_b_id: b_id,
        outcome: :liked_a,
        session_id: "session-3"
      })
      |> Repo.insert!()

      for _ <- 1..20 do
        {:ok, {left, right}} = Pairing.next_pair("session-3")
        pair = Comparison.canonical_pair(left, right)
        refute pair == {a_id, b_id}
        refute left.id == right.id
      end

      # third streamer allows other pairs
      assert s3.active
    end
  end
end
