defmodule Todo.Tasks.Subtasks.Subtask do
  @moduledoc false

  alias Todo.Tasks.Task

  use Ecto.Schema
  import Ecto.Changeset

  schema "subtasks" do
    field :completed, :boolean, default: false
    field :name, :string
    belongs_to :parent, Task

    timestamps()
  end

  @doc false
  def changeset(task, attrs) do
    task
    |> cast(attrs, [:name, :completed, :parent_id])
    |> validate_required([:name, :completed])
  end
end
