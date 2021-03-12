defmodule TodoWeb.TasksLive do
  use TodoWeb, :live_view

  alias Todo.Tasks.Subtasks
  alias Todo.Tasks.Subtasks.Subtask
  alias Todo.Tasks
  alias Todo.Tasks.Task

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
    {:ok, socket}
  end

  def render(assigns) do
    ~L"""
    <h1>Tasks</h1>
    <%= f = form_for @changeset, "#",  [phx_change: :validate, phx_submit: :create, class: "create-form"] %>
      <div class="field">
        <%= text_input f, :name, placeholder: "Name", phx_debounce: "2000" %>
        <%= error_tag f, :name %>
      </div>
      <%= submit "Create", phx_disable_with: "Saving..." %>
    </form>
    <%= for task <- @tasks do %>
      <div>
        <div class="task-header">
          <p phx-click="update" phx-value-id="<%= task.id %>" class="task-name completed-<%= task.completed %>">
            <%= task.id %> - <%= task.name %>
            <span><%= if task.completed, do: "completed", else: "" %></span>
          </p>
          <button class="alert-danger" phx-click="delete" phx-value-id="<%= task.id %>">Delete</button>
        </div>
        <%= ff = form_for task.changeset, "#", phx_change: :validate_subtask, phx_submit: :create_subtask, id: "subtask-form-#{task.id}", class: "create-form" %>
          <div class="field">
            <%= hidden_input ff, :parent_id, value: task.id %>
            <%= text_input ff, :name %>
          </div>
          <%= submit "Create", phx_disable_with: "Saving..." %>
        </form>
        <div class="subtasks-list">
          <%= for subtask <- task.subtasks do %>
            <div class="task-header">
              <p class="task-name completed-<%= subtask.completed %>" phx-click="update_subtask" phx-value-id="<%= subtask.id %>">
                <%= subtask.name %>
                <span><%= if subtask.completed, do: "completed", else: "" %></span>
              </p>
              <button class="alert-danger" phx-click="delete_subtask" phx-value-id="<%= subtask.id %>">Delete</button>
            </div>
          <% end %>
        </div>
      </div>
    <% end %>
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
        task =
          task
          |> Repo.preload(:subtasks)
          |> Map.merge(%{changeset: Subtasks.change_subtask(%Subtask{})})

        socket =
          assign(socket,
            tasks: [task | socket.assigns.tasks],
            changeset: Tasks.change_task(%Task{})
          )

        {:noreply, socket}

      {:error, changeset} ->
        socket = assign(socket, changeset: changeset)
        {:noreply, socket}
    end
  end

  def handle_event("update", %{"id" => id}, socket) do
    task = Tasks.get_task!(id)

    case Tasks.update_task(task, %{completed: !task.completed}) do
      {:ok, updated_task} ->
        Subtasks.update_all(updated_task.id, updated_task.completed)

        updated_task =
          updated_task
          |> Repo.preload(:subtasks)
          |> Map.merge(%{changeset: Subtasks.change_subtask(%Subtask{})})

        index = socket.assigns.tasks |> Enum.find_index(&(&1.id == updated_task.id))
        tasks = socket.assigns.tasks |> List.replace_at(index, updated_task)
        socket = assign(socket, tasks: tasks)
        {:noreply, socket}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  def handle_event("delete", %{"id" => id}, socket) do
    task = Tasks.get_task!(id)

    case Tasks.delete_task(task) do
      {:ok, deleted_task} ->
        tasks = socket.assigns.tasks |> Enum.filter(&(&1.id != deleted_task.id))
        socket = assign(socket, tasks: tasks)
        {:noreply, socket}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  def handle_event("validate_subtask", %{"subtask" => subtask_params}, socket) do
    changeset = Subtasks.change_subtask(%Subtask{}, subtask_params) |> Map.put(:action, :insert)
    tasks = update_task_changeset(socket.assigns.tasks, changeset)
    socket = assign(socket, tasks: tasks)
    {:noreply, socket}
  end

  def handle_event("create_subtask", %{"subtask" => subtask_params}, socket) do
    case Subtasks.create_subtask(subtask_params) do
      {:ok, subtask} ->
        socket = assign(socket, tasks: add_subtask(socket.assigns.tasks, subtask))
        {:noreply, socket}

      {:error, changeset} ->
        socket = assign(socket, changeset: changeset)
        {:noreply, socket}
    end
  end

  def handle_event("update_subtask", %{"id" => id}, socket) do
    subtask = Subtasks.get_subtask!(id)

    case Subtasks.update_subtask(subtask, %{completed: !subtask.completed}) do
      {:ok, updated_subtask} ->
        tasks = update_subtask(socket.assigns.tasks, updated_subtask)
        socket = assign(socket, tasks: tasks)
        {:noreply, socket}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  def handle_event("delete_subtask", %{"id" => id}, socket) do
    subtask = Subtasks.get_subtask!(id)

    case Subtasks.delete_subtask(subtask) do
      {:ok, deleted_subtask} ->
        tasks =
          delete_subtask(socket.assigns.tasks, deleted_subtask.parent_id, deleted_subtask.id)

        socket = assign(socket, tasks: tasks)
        {:noreply, socket}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  defp update_task_changeset(tasks, changeset) do
    tasks
    |> Enum.reduce([], fn task, acc ->
      if task.id == changeset.changes.parent_id do
        [task |> Map.merge(%{changeset: changeset}) | acc]
      else
        [task | acc]
      end
    end)
  end

  defp update_subtask(tasks, subtask) do
    tasks
    |> Enum.reduce([], fn task, acc ->
      if task.id == subtask.parent_id do
        index = task.subtasks |> Enum.find_index(&(&1.id == subtask.id))
        subtasks = task.subtasks |> List.replace_at(index, subtask)
        [task |> Map.merge(%{subtasks: subtasks}) | acc]
      else
        [task | acc]
      end
    end)
  end

  defp add_subtask(tasks, subtask) do
    tasks
    |> Enum.reduce([], fn task, acc ->
      if task.id == subtask.parent_id do
        changeset = Subtasks.change_subtask(%Subtask{})
        [task |> Map.merge(%{changeset: changeset, subtasks: [subtask | task.subtasks]}) | acc]
      else
        [task | acc]
      end
    end)
  end

  defp delete_subtask(tasks, task_id, subtask_id) do
    tasks
    |> Enum.reduce([], fn task, acc ->
      if task.id == task_id do
        [task |> Map.merge(%{subtasks: task.subtasks |> Enum.filter(&(&1.id != subtask_id))})]
      else
        [task | acc]
      end
    end)
  end
end
