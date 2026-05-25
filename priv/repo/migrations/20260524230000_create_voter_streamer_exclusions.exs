defmodule ComparisonApp.Repo.Migrations.CreateVoterStreamerExclusions do
  use Ecto.Migration

  def change do
    create table(:voter_streamer_exclusions) do
      add :ip_hash, :string, null: false
      add :streamer_id, references(:streamers, on_delete: :delete_all), null: false
      add :expires_at, :utc_datetime, null: false

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create unique_index(:voter_streamer_exclusions, [:ip_hash, :streamer_id])
    create index(:voter_streamer_exclusions, [:ip_hash, :expires_at])
  end
end
