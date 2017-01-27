defmodule Juggler.BuildController do
  use Juggler.Web, :controller

  alias Juggler.Build
  alias Porcelain.Process, as: Proc
  alias Porcelain.Result

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
        |> redirect(to: project_build_path(conn, :show, project_id, build))
      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Unable to start build.")
        |> redirect(to: project_path(conn, :show, project_id))
    end
  end

  def show(conn, %{"id" => id}) do
    build = Build |> Repo.get!(id) |> Repo.preload([:project])
    commands = String.split(build.project.build_commands, "\n")

    proc = %Proc{pid: pid} = Porcelain.spawn_shell("ls", out: {:send, self()})

    receive do
      {^pid, :data, :out, data} -> Juggler.Endpoint.broadcast("build:1", "new_msg", %{body: data})
    end

    render(conn, "show.html", build: build, commands: commands)
  end
end
