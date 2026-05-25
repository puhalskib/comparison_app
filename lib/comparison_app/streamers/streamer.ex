defmodule ComparisonApp.Streamers.Streamer do
  use Ecto.Schema
  import Ecto.Changeset

  schema "streamers" do
    field :twitch_id, :string
    field :login, :string
    field :display_name, :string
    field :profile_image_url, :string
    field :avatar_path, :string
    field :rating, :float, default: 1500.0
    field :rd, :float, default: 350.0
    field :volatility, :float, default: 0.06
    field :comparison_count, :integer, default: 0
    field :last_compared_at, :utc_datetime
    field :active, :boolean, default: true

    timestamps(type: :utc_datetime)
  end

  @required [:twitch_id, :login, :display_name]
  @optional [
    :profile_image_url,
    :avatar_path,
    :rating,
    :rd,
    :volatility,
    :comparison_count,
    :last_compared_at,
    :active
  ]

  def changeset(streamer, attrs) do
    streamer
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
    |> unique_constraint(:twitch_id)
  end

  def rating_tuple(%__MODULE__{} = s) do
    {s.rating, s.rd, s.volatility}
  end

  def apply_rating(%__MODULE__{} = s, {rating, rd, volatility}) do
    %{s | rating: rating, rd: rd, volatility: volatility}
  end
end
