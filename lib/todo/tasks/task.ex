defmodule Todo.Tasks.Task do
  @moduledoc false

  alias Todo.Tasks.Subtasks.Subtask

  use Ecto.Schema
  import Ecto.Changeset

  schema "tasks" do
    field :completed, :boolean, default: false
    field :name, :string

    has_many :subtasks, Subtask, foreign_key: :parent_id, on_delete: :delete_all

    timestamps()
  end

  @doc false
  def changeset(task, attrs) do
    task
    |> cast(attrs, [:name, :completed])
    |> validate_required([:name, :completed])
    |> validate_length(:name, min: 3, max: 100)
  end
end
