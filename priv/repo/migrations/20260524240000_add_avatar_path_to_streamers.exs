defmodule ComparisonApp.Repo.Migrations.AddAvatarPathToStreamers do
  use Ecto.Migration

  def change do
    alter table(:streamers) do
      add :avatar_path, :string
    end
  end
end
