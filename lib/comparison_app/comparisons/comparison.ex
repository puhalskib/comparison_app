defmodule ComparisonApp.Comparisons.Comparison do
  use Ecto.Schema
  import Ecto.Changeset

  alias ComparisonApp.Streamers.Streamer

  @outcomes [:liked_a, :liked_b, :unknown_a, :unknown_b, :unknown_both]

  schema "comparisons" do
    belongs_to :streamer_a, Streamer
    belongs_to :streamer_b, Streamer
    field :outcome, Ecto.Enum, values: @outcomes
    field :session_id, :string

    timestamps(type: :utc_datetime, updated_at: false)
  end

  def changeset(comparison, attrs) do
    comparison
    |> cast(attrs, [:streamer_a_id, :streamer_b_id, :outcome, :session_id])
    |> validate_required([:streamer_a_id, :streamer_b_id, :outcome, :session_id])
    |> validate_pair_order()
    |> foreign_key_constraint(:streamer_a_id)
    |> foreign_key_constraint(:streamer_b_id)
    |> unique_constraint([:session_id, :streamer_a_id, :streamer_b_id],
      name: :comparisons_session_pair_index
    )
  end

  defp validate_pair_order(changeset) do
    a_id = get_field(changeset, :streamer_a_id)
    b_id = get_field(changeset, :streamer_b_id)

    if a_id && b_id && a_id >= b_id do
      add_error(changeset, :streamer_b_id, "must be greater than streamer_a_id")
    else
      changeset
    end
  end

  def canonical_pair(%Streamer{id: id_a}, %Streamer{id: id_b}) when id_a < id_b,
    do: {id_a, id_b}

  def canonical_pair(%Streamer{} = a, %Streamer{} = b), do: canonical_pair(b, a)
end
