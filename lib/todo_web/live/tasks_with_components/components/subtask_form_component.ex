defmodule TodoWeb.TasksWithComponents.SubtaskFormComponent do
  use TodoWeb, :live_component

  alias Todo.Tasks.Subtasks
  alias Todo.Tasks.Subtasks.Subtask

  alias TodoWeb.TasksWithComponents.TaskComponent

  def mount(socket) do
    changeset = Subtasks.change_subtask(%Subtask{})
    socket = assign(socket, changeset: changeset)
    {:ok, socket}
  end

  def render(assigns) do
    ~L"""
    <%= ff = form_for @changeset, "#", phx_target: @myself, phx_change: :validate_subtask, phx_submit: :create_subtask, class: "create-form" %>
      <div class="field">
        <%= hidden_input ff, :parent_id, value: @id, id: false %>
        <%= text_input ff, :name, id: false, autocomplete: "off" %>
        <%= error_tag ff, :name %>
      </div>
      <%= submit "Create", phx_disable_with: "Saving..." %>
    </form>
    """
  end

  def handle_event("validate_subtask", %{"subtask" => subtask_params}, socket) do
    changeset = Subtasks.change_subtask(%Subtask{}, subtask_params) |> Map.put(:action, :insert)
    socket = assign(socket, changeset: changeset)
    {:noreply, socket}
  end

  def handle_event("create_subtask", %{"subtask" => subtask_params}, socket) do
    case Subtasks.create_subtask(subtask_params) do
      {:ok, subtask} ->
        send_update(TaskComponent, id: socket.assigns.id, action: :create, subtask: subtask)
        socket = assign(socket, changeset: Subtasks.change_subtask(%Subtask{}))
        {:noreply, socket}

      {:error, changeset} ->
        socket = assign(socket, changeset: changeset)
        {:noreply, socket}
    end
  end
end
