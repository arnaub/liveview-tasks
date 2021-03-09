defmodule TodoWeb.TasksWithComponents.SubtaskComponent do
  use TodoWeb, :live_component

  alias Todo.Tasks.Subtasks

  alias TodoWeb.TasksWithComponents.TaskComponent

  def render(assigns) do
    ~L"""
    <div class="task-header">
      <p class="task-name completed-<%= @subtask.completed %>" phx-target="<%= @myself %>" phx-click="update" phx-value-id="<%= @subtask.id %>">
        <%= @subtask.name %>
        <span><%= if @subtask.completed, do: "completed", else: "" %></span>
      </p>
      <button class="alert-danger" phx-target="<%= @myself %>" phx-click="delete" phx-value-id="<%= @subtask.id %>">Delete</button>
    </div>
    """
  end

  def handle_event("update", %{"id" => id}, socket) do
    subtask = Subtasks.get_subtask!(id)

    case Subtasks.update_subtask(subtask, %{completed: !subtask.completed}) do
      {:ok, updated_subtask} ->
        socket = assign(socket, subtask: updated_subtask)
        {:noreply, socket}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  def handle_event("delete", %{"id" => id}, socket) do
    subtask = Subtasks.get_subtask!(id)

    case Subtasks.delete_subtask(subtask) do
      {:ok, deleted_subtask} ->

        send_update TaskComponent, id: deleted_subtask.parent_id, action: :delete, subtask_id: deleted_subtask.id
        {:noreply, socket}

      {:error, _} ->
        {:noreply, socket}
    end
  end
end
