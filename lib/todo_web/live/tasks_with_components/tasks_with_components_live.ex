defmodule TodoWeb.TasksWithComponentsLive do
  use TodoWeb, :live_view

  # Contexts
  alias Todo.Tasks.Subtasks
  alias Todo.Tasks.Subtasks.Subtask
  alias Todo.Tasks
  alias Todo.Tasks.Task

  # Components
  alias TodoWeb.TasksWithComponents.TaskComponent
  alias TodoWeb.TasksWithComponents.TaskFormComponent

  alias Todo.Repo

  def mount(_params, _session, socket) do
    tasks =
      Tasks.list_tasks()
      |> Repo.preload(:subtasks)
      |> Enum.map(fn task ->
        task
        |> Map.merge(%{changeset: Subtasks.change_subtask(%Subtask{})})
      end)
      |> Enum.sort_by(& &1.id, :desc)

    changeset = Tasks.change_task(%Task{})
    socket = assign(socket, tasks: tasks, changeset: changeset)
    {:ok, socket, temporary_assigns: [tasks: []]}
  end

  def render(assigns) do
    ~L"""
    <h1>Tasks</h1>
    <%= live_component @socket, TaskFormComponent, id: "create-task" %>
    <div id="tasks" phx-update="prepend" phx-hook="TasksList">
      <%= for task <- @tasks do %>
        <div class="task-card" id="task-<%= task.id %>">
          <%= live_component @socket, TaskComponent, id: task.id, task: task, subtasks: task.subtasks %>
        </div>
      <% end %>
    </div>
    """
  end

  def handle_info({:create_task, %{task: task}}, socket) do
    task = task |> Repo.preload(:subtasks)
    socket = update(socket, :tasks, fn tasks -> [task | tasks] end)
    {:noreply, socket}
  end

  def handle_info({:delete_task, %{task_id: task_id}}, socket) do
    socket = update(socket, :tasks, fn tasks -> tasks |> Enum.filter(&(&1.id != task_id))end)
    socket = push_event(socket, "delete-task", %{id: task_id})
    {:noreply, socket}
  end
end
