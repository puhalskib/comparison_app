defmodule ComparisonApp.VoterExclusions.Exclusion do
  use Ecto.Schema
  import Ecto.Changeset

  alias ComparisonApp.Streamers.Streamer

  schema "voter_streamer_exclusions" do
    belongs_to :streamer, Streamer
    field :ip_hash, :string
    field :expires_at, :utc_datetime

    timestamps(type: :utc_datetime, updated_at: false)
  end

  def changeset(exclusion, attrs) do
    exclusion
    |> cast(attrs, [:ip_hash, :streamer_id, :expires_at])
    |> validate_required([:ip_hash, :streamer_id, :expires_at])
    |> unique_constraint([:ip_hash, :streamer_id])
    |> foreign_key_constraint(:streamer_id)
  end
end
