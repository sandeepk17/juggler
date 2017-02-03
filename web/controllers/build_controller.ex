defmodule Juggler.BuildController do
  use Juggler.Web, :controller

  alias Juggler.Build

  plug Juggler.Plugs.Authenticated

  def create(conn, %{"project_id" => project_id}) do
    changeset = Build.changeset(%Build{}, %{
      :project_id => project_id,
      :key => Integer.to_string(DateTime.to_unix(DateTime.utc_now)),
      :state => "new"
      })

    case Repo.insert(changeset) do
      {:ok, build} ->
        conn
        |> put_flash(:info, "Build started successfully.")
        |> start_build(build.id)
        |> redirect(to: project_build_path(conn, :show, project_id, build))
      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Unable to start build.")
        |> redirect(to: project_path(conn, :show, project_id))
    end
  end

  def show(conn, %{"id" => id}) do
    build = Build |> Repo.get!(id) |> Repo.preload([:project])
    render(conn, "show.html", build: build)
  end

  def start_build(conn, build_id) do
    Juggler.BuildServer.new_build(build_id)
    conn
  end
end
