defmodule TodoWeb.TasksWithComponents.TaskComponent do
  use TodoWeb, :live_component

  # Contexts
  alias Todo.Tasks
  alias Todo.Tasks.Subtasks.Subtask
  alias Todo.Tasks.Subtasks
  alias Todo.Tasks.Subtasks.Subtask

  alias Todo.Repo

  # Components
  alias TodoWeb.TasksWithComponents.SubtaskComponent
  alias TodoWeb.TasksWithComponents.SubtaskFormComponent

  def mount(socket) do
    socket = assign(socket, changeset: Subtasks.change_subtask(%Subtask{}))
    {:ok, socket}
  end

  def update(%{action: :create, subtask: subtask}, socket) do
    socket = update(socket, :subtasks, fn subtasks -> [subtask | subtasks] end)
    {:ok, socket}
  end

  def update(%{action: :delete, subtask_id: subtask_id}, socket) do
    socket = update(socket, :subtasks, fn subtasks -> subtasks |> Enum.filter(&(&1.id != subtask_id)) end)
    socket = push_event(socket, "delete-subtask", %{id: subtask_id})
    {:ok, socket}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end


  def render(assigns) do
    ~L"""
    <div class="task-header">
      <p phx-click="update" phx-target="<%= @myself %>" phx-value-id="<%= @task.id %>" class="task-name completed-<%= @task.completed %>">
        <%= @task.id %> - <%= @task.name %>
        <span><%= if @task.completed, do: "completed", else: "" %></span>
      </p>
      <button class="alert-danger" phx-target="<%= @myself %>" phx-click="delete" phx-value-id="<%= @task.id %>">Delete</button>
    </div>
    <div>
      <%= live_component @socket, SubtaskFormComponent, id: @task.id %>
    </div>
    <div id="subtasks-list-<%= @task.id %>" phx-update="prepend">
      <%= for subtask <- @subtasks do %>
        <div id="subtask-<%= subtask.id %>">
          <%= live_component @socket, SubtaskComponent, id: subtask.id, subtask: subtask %>
        </div>
      <% end %>
    </div>
    """
  end

  def handle_event("update", %{"id" => id}, socket) do
    task = Tasks.get_task!(id)

    case Tasks.update_task(task, %{completed: !task.completed}) do
      {:ok, updated_task} ->
        Subtasks.update_all(updated_task.id, updated_task.completed)

        updated_task =
          updated_task
          |> Repo.preload(:subtasks)

        socket = assign(socket, task: updated_task)
        socket = update(socket, :subtasks, fn _subtasks -> updated_task.subtasks end)
        {:noreply, socket}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  def handle_event("delete", %{"id" => id}, socket) do
    task = Tasks.get_task!(id)

    case Tasks.delete_task(task) do
      {:ok, deleted_task} ->
        send self(), {:delete_task, %{task_id: deleted_task.id}}
        {:noreply, socket}
      {:error, _} ->
        {:noreply, socket}
    end
  end
end
