defmodule Todo.Tasks.Subtasks do
  @moduledoc """
  The Tasks context.
  """

  import Ecto.Query, warn: false
  alias Todo.Repo

  alias Todo.Tasks.Subtasks.Subtask

  @doc """
  Returns the list of tasks.

  ## Examples

      iex> list_subtasks()
      [%Subtask{}, ...]

  """
  def list_subtasks do
    Repo.all(Subtask)
  end

  @doc """
  Gets a single subtask.

  Raises `Ecto.NoResultsError` if the Subtask does not exist.

  ## Examples

      iex> get_subtask!(123)
      %Subtask{}

      iex> get_subtask!(456)
      ** (Ecto.NoResultsError)

  """
  def get_subtask!(id), do: Repo.get!(Subtask, id)

  @doc """
  Creates a subtask.

  ## Examples

      iex> create_subtask(%{field: value})
      {:ok, %Subtask{}}

      iex> create_subtask(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_subtask(attrs \\ %{}) do
    %Subtask{}
    |> Subtask.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a subtask.

  ## Examples

      iex> update_subtask(subtask, %{field: new_value})
      {:ok, %Subtask{}}

      iex> update_subtask(subtask, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_subtask(%Subtask{} = subtask, attrs) do
    subtask
    |> Subtask.changeset(attrs)
    |> Repo.update()
  end

  def update_all(parent_id, completed) do
    from(s in Subtask, where: s.parent_id == ^parent_id)
    |> Repo.update_all(set: [completed: completed])
  end

  @doc """
  Deletes a subtask.

  ## Examples

      iex> delete_subtask(subtask)
      {:ok, %Subtask{}}

      iex> delete_subtask(subtask)
      {:error, %Ecto.Changeset{}}

  """
  def delete_subtask(%Subtask{} = subtask) do
    Repo.delete(subtask)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking subtask changes.

  ## Examples

      iex> change_subtask(subtask)
      %Ecto.Changeset{data: %Subtask{}}

  """
  def change_subtask(%Subtask{} = subtask, attrs \\ %{}) do
    Subtask.changeset(subtask, attrs)
  end
end
