defmodule Juggler.SSHKeysController do
  use Juggler.Web, :controller

  alias Juggler.SSHKey
  alias Juggler.Project

  plug Juggler.Plugs.Authenticated
  plug :authorize_project

  def index(conn, %{"project_id" => project_id}) do
      project = Project |> Repo.get!(project_id) |> Repo.preload([:ssh_keys])
      render conn, "index.json", ssh_keys: project.ssh_keys
  end

  def create(conn, %{"project_id" => project_id, "ssh_key" => ssh_key_params}) do
    changeset = SSHKey.changeset(%SSHKey{}, Map.merge(ssh_key_params, %{"project_id" => project_id}))

    case Repo.insert(changeset) do
      {:ok, ssh_key} ->
        conn
        |> put_status(:created)
        |> render("show.json", ssh_key: ssh_key)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Juggler.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    ssh_key = Repo.get!(SSHKey, id)
    Repo.delete!(ssh_key)

    send_resp(conn, :no_content, "")
  end

  defp authorize_project(conn, _) do
    case conn.params do
      %{"project_id" => id} ->
        project = Project |> Repo.get!(id)
        if project.user_id == current_user(conn).id do
          conn
        else
          conn |> put_flash(:info, "You can't access that page") |> redirect(to: project_path(conn, :index)) |> halt
        end
      _ ->
        conn
    end
  end
end
