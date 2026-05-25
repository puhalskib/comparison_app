defmodule ComparisonApp.VoterExclusions do
  @moduledoc """
  Temporary per-IP blocks for streamers a voter marked as unknown.
  """

  import Ecto.Query, warn: false

  alias ComparisonApp.Repo
  alias ComparisonApp.VoterExclusions.Exclusion

  @default_block_hours 24

  def hash_ip(remote_ip) when is_tuple(remote_ip) do
    remote_ip
    |> :inet.ntoa()
    |> to_string()
    |> hash_ip_string()
  end

  def hash_ip_string(ip_string) when is_binary(ip_string) do
    salt = Application.get_env(:comparison_app, :ip_hash_salt, "")

    :crypto.hash(:sha256, salt <> ip_string)
    |> Base.encode16(case: :lower)
  end

  def block_streamers(ip_hash, streamer_ids, hours \\ @default_block_hours)
      when is_binary(ip_hash) do
    expires_at =
      DateTime.utc_now()
      |> DateTime.add(hours, :hour)
      |> DateTime.truncate(:second)

    Enum.each(streamer_ids, fn streamer_id ->
      attrs = %{ip_hash: ip_hash, streamer_id: streamer_id, expires_at: expires_at}

      %Exclusion{}
      |> Exclusion.changeset(attrs)
      |> Repo.insert(
        on_conflict: {:replace, [:expires_at]},
        conflict_target: [:ip_hash, :streamer_id]
      )
    end)

    :ok
  end

  def blocked_streamer_ids(nil), do: MapSet.new()
  def blocked_streamer_ids(""), do: MapSet.new()

  def blocked_streamer_ids(ip_hash) when is_binary(ip_hash) do
    now = DateTime.utc_now()

    from(e in Exclusion,
      where: e.ip_hash == ^ip_hash and e.expires_at > ^now,
      select: e.streamer_id
    )
    |> Repo.all()
    |> MapSet.new()
  end

  def purge_expired do
    now = DateTime.utc_now()

    from(e in Exclusion, where: e.expires_at <= ^now)
    |> Repo.delete_all()
  end
end
