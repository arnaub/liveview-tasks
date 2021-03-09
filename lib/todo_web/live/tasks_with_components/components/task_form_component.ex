defmodule TodoWeb.TasksWithComponents.TaskFormComponent do
  use TodoWeb, :live_component

  alias Todo.Tasks
  alias Todo.Tasks.Task

  alias Todo.Repo

  def mount(socket) do
    socket = assign(socket, changeset: Tasks.change_task(%Task{}))
    {:ok, socket}
  end

  def render(assigns) do
    ~L"""
    <%= f = form_for @changeset, "#", [phx_target: @myself, phx_change: :validate, phx_submit: :create, class: "create-form"] %>
      <div class="field">
        <%= text_input f, :name, placeholder: "Name", phx_debounce: "2000", autocomplete: "off" %>
        <%= error_tag f, :name %>
      </div>
      <%= submit "Create", phx_disable_with: "Saving..." %>
    </form>
    """
  end

  def handle_event("validate", %{"task" => task_params}, socket) do
    changeset = Tasks.change_task(%Task{}, task_params) |> Map.put(:action, :insert)
    socket = assign(socket, changeset: changeset)
    {:noreply, socket}
  end

  def handle_event("create", %{"task" => task_params}, socket) do
    case Tasks.create_task(task_params) do
      {:ok, task} ->
        send self(), {:create_task, %{task: task}}
        socket = assign(socket, changeset: Tasks.change_task(%Task{}))
        {:noreply, socket}

      {:error, changeset} ->
        socket = assign(socket, changeset: changeset)
        {:noreply, socket}
    end
  end
end
