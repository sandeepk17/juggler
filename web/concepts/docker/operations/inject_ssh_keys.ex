defmodule Juggler.Docker.Operations.InjectSSHKeys do
  alias Porcelain.Result
  alias Juggler.Repo
  alias Juggler.Project
  require Logger
  import Monad.Result, only: [success: 1,
                              error: 1]

  def call(container_id, project_id) do
    project = Project |> Repo.get!(project_id) |> Repo.preload([:ssh_keys])
    ssh_keys = project.ssh_keys
    %Result{out: output, status: status} = Porcelain.shell("docker exec " <> container_id <> " mkdir /root/.ssh", err: :out)
    case status do
      0 ->
        inject_keys(container_id, ssh_keys)
      _ -> error("Failed to create /root/.ssh dir for docker cont: " <> container_id)
    end
  end

  def inject_keys(container_id, ssh_keys) do
    case List.pop_at(ssh_keys, 0) do
      {nil, []} ->
        success(container_id)
      {ssh_key, ssh_keys} ->
        {:ok, status} = inject_key(container_id, ssh_key)
        case status == 0 do
          true  -> inject_keys(container_id, ssh_keys)
          false -> error("Injecting ssh key into container " <> container_id <> " failed.")
        end
    end
  end

  def inject_key(container_id, ssh_key) do
    ssh_key_id = Integer.to_string(ssh_key.id)
    Logger.info " ---> Injecting ssh key " <> ssh_key_id
    docker_command = "docker exec " <> container_id <> " bash -c 'echo \"" <> ssh_key.data <> "\" >> /root/.ssh/id_rsa" <> ssh_key_id <> "'"
    %Result{out: output, status: status} = Porcelain.shell(docker_command, err: :out)
    Logger.info " ---> Finished injecting ssh key " <> ssh_key_id <> " result: " <> Integer.to_string(status)
    {:ok, status}
    case status == 0 do
      true  ->
        Logger.info " ---> Adding ssh key to config" <> ssh_key_id
        docker_command = "docker exec " <> container_id <> " bash -c 'echo \"IdentityFile /root/.ssh/id_rsa" <> ssh_key_id <> "\" >> /root/.ssh/config'"
        %Result{out: output, status: status} = Porcelain.shell(docker_command, err: :out)
        Logger.info " ---> Finished adding ssh key to config " <> ssh_key_id <> " result: " <> Integer.to_string(status)
        {:ok, status}
      false ->
        {:ok, status}
    end
  end
end
