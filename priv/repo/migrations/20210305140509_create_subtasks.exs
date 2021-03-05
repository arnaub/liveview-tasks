defmodule Todo.Repo.Migrations.CreateSubtasks do
  use Ecto.Migration

  def change do
    create table(:subtasks) do
      add :name, :string
      add :completed, :boolean, default: false, null: false
      add :parent_id, references(:tasks, on_delete: :nothing)

      timestamps()
    end

    create index(:subtasks, [:parent_id])
  end
end
