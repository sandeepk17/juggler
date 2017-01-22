defmodule Juggler.Repo.Migrations.CreateBuild do
  use Ecto.Migration

  def change do
    create table(:builds) do
      add :key, :string
      add :output, :text
      add :project_id, references(:projects, on_delete: :nothing)

      timestamps()
    end
    create index(:builds, [:project_id])

  end
end
