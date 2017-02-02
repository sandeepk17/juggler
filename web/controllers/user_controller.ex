defmodule Juggler.UserController do
  use Juggler.Web, :controller
  alias Juggler.User
  import Comeonin.Bcrypt
  import Juggler.UserOperations

  def new(conn, _params) do
    changeset = User.changeset(%User{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    changeset = User.changeset(%User{}, Map.merge(user_params, %{"encrypted_password" => hashpwsalt(user_params["password"])}))

    case Repo.insert(changeset) do
      {:ok, _project} ->
        conn
        |> put_flash(:info, "Thank you for signup")
        |> redirect(to: project_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def login(conn, _params) do
    render(conn, "login.html")
  end

  def authenticate(conn, %{"login" => %{"email" => email, "password" => password}}) do
    user = nil
    result = success(user)
             ~>> fn user -> validate_user_exists(email) end
             ~>> fn user -> validate_password(user, password) end

   if success?(result) do # %Monad.Result{type: :success, value: user}
    value = unwrap!(result) # Same as result.value
    conn
    |> put_flash(:info, "Welcome to Juggler")
    |> redirect(to: project_path(conn, :index))
   else
    render(conn, "login.html")
   end
  end
end
