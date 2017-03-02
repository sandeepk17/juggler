defmodule Juggler.Build.Operations.StartContainer do
  alias Juggler.Docker.Operations.StartDockerContainer
  alias Juggler.Build.Operations.UpdateState
  alias Juggler.Source.Operations.GetEnvVars
  alias Juggler.{Repo, Build, Source}
  require Logger
  import Monad.Result, only: [success?: 1,
                              unwrap!: 1,
                              success: 1,
                              error: 1]

  def call(build) do
    custom_env_vars = GetEnvVars.call(build.source_id)
    result = StartDockerContainer.call(build.project_id, custom_env_vars)

    if success?(result) do
      changeset = Build.changeset(build, %{:container_id => result.value})
      case Repo.update(changeset) do
        {:ok, build} ->
          Logger.info " ---> New docker cont " <> build.container_id <> " build: " <> Integer.to_string(build.id)
          UpdateState.call(build, "running")
          success(build)
        {:error, _changeset} ->
          error_msg = "Error updating build " <> Integer.to_string(build.id) <> " with container_id"
          Logger.error error_msg
          error(error_msg)
      end
    else
      result
    end
  end

end
