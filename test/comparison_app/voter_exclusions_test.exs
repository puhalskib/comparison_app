defmodule ComparisonApp.VoterExclusionsTest do
  use ComparisonApp.DataCase, async: true

  alias ComparisonApp.Streamers.Streamer
  alias ComparisonApp.VoterExclusions
  alias ComparisonApp.VoterExclusions.Exclusion

  defp insert_streamer(login) do
    %Streamer{}
    |> Streamer.changeset(%{
      twitch_id: "tw_#{login}",
      login: login,
      display_name: login
    })
    |> Repo.insert!()
  end

  test "hash_ip_string is deterministic" do
    a = VoterExclusions.hash_ip_string("127.0.0.1")
    b = VoterExclusions.hash_ip_string("127.0.0.1")
    assert a == b
    assert byte_size(a) == 64
  end

  test "block_streamers and blocked_streamer_ids" do
    s = insert_streamer("blocked_one")
    ip = VoterExclusions.hash_ip_string("10.0.0.1")

    :ok = VoterExclusions.block_streamers(ip, [s.id], 24)
    blocked = VoterExclusions.blocked_streamer_ids(ip)
    assert MapSet.member?(blocked, s.id)
  end

  test "expired blocks are not returned" do
    s = insert_streamer("expired")
    ip = VoterExclusions.hash_ip_string("10.0.0.2")

    past = DateTime.utc_now() |> DateTime.add(-1, :hour) |> DateTime.truncate(:second)

    %Exclusion{}
    |> Exclusion.changeset(%{ip_hash: ip, streamer_id: s.id, expires_at: past})
    |> Repo.insert!()

    refute MapSet.member?(VoterExclusions.blocked_streamer_ids(ip), s.id)
  end

  test "block extends expiry on conflict" do
    s = insert_streamer("extend")
    ip = VoterExclusions.hash_ip_string("10.0.0.3")

    soon = DateTime.utc_now() |> DateTime.add(1, :hour) |> DateTime.truncate(:second)

    %Exclusion{}
    |> Exclusion.changeset(%{ip_hash: ip, streamer_id: s.id, expires_at: soon})
    |> Repo.insert!()

    :ok = VoterExclusions.block_streamers(ip, [s.id], 24)

    row = Repo.get_by!(Exclusion, ip_hash: ip, streamer_id: s.id)
    assert DateTime.compare(row.expires_at, soon) == :gt
  end
end
