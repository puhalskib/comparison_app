defmodule ComparisonApp.Repo.Migrations.CreateStreamersComparisons do
  use Ecto.Migration

  def change do
    create table(:streamers) do
      add :twitch_id, :string, null: false
      add :login, :string, null: false
      add :display_name, :string, null: false
      add :profile_image_url, :string
      add :rating, :float, null: false, default: 1500.0
      add :rd, :float, null: false, default: 350.0
      add :volatility, :float, null: false, default: 0.06
      add :comparison_count, :integer, null: false, default: 0
      add :last_compared_at, :utc_datetime
      add :active, :boolean, null: false, default: true

      timestamps(type: :utc_datetime)
    end

    create unique_index(:streamers, [:twitch_id])
    create index(:streamers, [:active])
    create index(:streamers, [:rating])

    create table(:comparisons) do
      add :streamer_a_id, references(:streamers, on_delete: :nothing), null: false
      add :streamer_b_id, references(:streamers, on_delete: :nothing), null: false
      add :outcome, :string, null: false
      add :session_id, :string, null: false

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:comparisons, [:session_id])
    create index(:comparisons, [:streamer_a_id, :streamer_b_id])

    create unique_index(:comparisons, [:session_id, :streamer_a_id, :streamer_b_id],
             name: :comparisons_session_pair_index
           )

    create table(:rating_snapshots) do
      add :streamer_id, references(:streamers, on_delete: :delete_all), null: false
      add :rating, :float, null: false
      add :rd, :float, null: false
      add :comparison_id, references(:comparisons, on_delete: :nilify_all)

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:rating_snapshots, [:streamer_id, :inserted_at])
  end
end
