defmodule ComparisonApp.Ratings.Snapshot do
  use Ecto.Schema
  import Ecto.Changeset

  alias ComparisonApp.Streamers.Streamer
  alias ComparisonApp.Comparisons.Comparison

  schema "rating_snapshots" do
    belongs_to :streamer, Streamer
    field :rating, :float
    field :rd, :float
    belongs_to :comparison, Comparison

    timestamps(type: :utc_datetime, updated_at: false)
  end

  def changeset(snapshot, attrs) do
    snapshot
    |> cast(attrs, [:streamer_id, :rating, :rd, :comparison_id])
    |> validate_required([:streamer_id, :rating, :rd])
    |> foreign_key_constraint(:streamer_id)
  end
end
