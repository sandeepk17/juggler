defmodule Juggler.Repo.Migrations.CreateProject do
  use Ecto.Migration

  def change do
    create table(:projects) do
      add :name, :string
      add :build_commands, :string
      add :env_vars, :string
      add :docker_image, :string
      add :dockerfile, :text
      add :branches, :text
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps()
    end
    create index(:projects, [:user_id])

  end
end
