defmodule ComparisonApp.Ratings.EngineTest do
  use ComparisonApp.DataCase, async: true

  alias ComparisonApp.Comparisons.Comparison
  alias ComparisonApp.Ratings.Engine
  alias ComparisonApp.Ratings.Snapshot
  alias ComparisonApp.Streamers.Streamer
  alias ComparisonApp.VoterExclusions
  alias ComparisonApp.VoterExclusions.Exclusion

  defp insert_streamer(login, rating \\ 1500.0) do
    %Streamer{}
    |> Streamer.changeset(%{
      twitch_id: login,
      login: login,
      display_name: String.capitalize(login),
      rating: rating,
      rd: 200.0,
      volatility: 0.06
    })
    |> Repo.insert!()
  end

  describe "outcome_to_update/1" do
    test "maps all outcomes" do
      assert Engine.outcome_to_update(:liked_a) == {1.0, true, true}
      assert Engine.outcome_to_update(:liked_b) == {0.0, true, true}
      assert Engine.outcome_to_update(:unknown_a) == {0.0, false, true}
      assert Engine.outcome_to_update(:unknown_b) == {1.0, true, false}
      assert Engine.outcome_to_update(:unknown_both) == {0.5, false, false}
    end
  end

  describe "submit_vote/4" do
    setup do
      a = insert_streamer("alpha")
      b = insert_streamer("beta", 1400.0)
      %{a: a, b: b}
    end

    test "liked_a updates both streamers and creates snapshots", %{a: a, b: b} do
      assert {:ok, result} = Engine.submit_vote(a, b, :liked_a, "sess-1")
      assert %Comparison{outcome: :liked_a} = result.comparison

      a_db = Repo.get!(Streamer, a.id)
      b_db = Repo.get!(Streamer, b.id)
      assert a_db.rating > a.rating
      assert b_db.rating < b.rating
      assert a_db.comparison_count == 1
      assert b_db.comparison_count == 1

      assert Repo.aggregate(from(s in Snapshot, where: s.streamer_id == ^a.id), :count) == 1
      assert Repo.aggregate(from(s in Snapshot, where: s.streamer_id == ^b.id), :count) == 1
    end

    test "unknown_both records comparison without rating changes", %{a: a, b: b} do
      assert {:ok, result} = Engine.submit_vote(a, b, :unknown_both, "sess-2")

      a_db = Repo.get!(Streamer, a.id)
      b_db = Repo.get!(Streamer, b.id)
      assert a_db.rating == a.rating
      assert b_db.rating == b.rating
      assert a_db.comparison_count == 0
      assert %Comparison{outcome: :unknown_both} = result.comparison
      assert Repo.aggregate(Snapshot, :count) == 0
    end

    test "unknown_a only updates streamer b", %{a: a, b: b} do
      assert {:ok, _} = Engine.submit_vote(a, b, :unknown_a, "sess-3")

      a_db = Repo.get!(Streamer, a.id)
      b_db = Repo.get!(Streamer, b.id)
      assert a_db.rating == a.rating
      assert b_db.rating != b.rating
      assert a_db.comparison_count == 0
      assert b_db.comparison_count == 1
    end

    test "unknown_b only updates streamer a", %{a: a, b: b} do
      assert {:ok, _} = Engine.submit_vote(a, b, :unknown_b, "sess-4")

      a_db = Repo.get!(Streamer, a.id)
      b_db = Repo.get!(Streamer, b.id)
      assert a_db.rating != a.rating
      assert b_db.rating == b.rating
      assert a_db.comparison_count == 1
      assert b_db.comparison_count == 0
    end

    test "rejects duplicate session pair vote", %{a: a, b: b} do
      assert {:ok, _} = Engine.submit_vote(a, b, :liked_a, "sess-dup")
      assert {:error, _} = Engine.submit_vote(a, b, :liked_b, "sess-dup")
    end

    test "unknown_a blocks streamer a for ip", %{a: a, b: b} do
      ip = VoterExclusions.hash_ip_string("192.168.1.10")
      assert {:ok, _} = Engine.submit_vote(a, b, :unknown_a, "sess-ip", ip)

      assert Repo.get_by(Exclusion, ip_hash: ip, streamer_id: a.id)
      refute Repo.get_by(Exclusion, ip_hash: ip, streamer_id: b.id)
    end
  end
end
