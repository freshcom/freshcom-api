defmodule BlueJet.Authentication do
  alias BlueJet.Repo
  alias BlueJet.User
  alias BlueJet.Jwt

  def get_jwt(%{ "email" => email, "password" => password }), do: get_jwt(%{ email: email, password: password })
  def get_jwt(%{ email: nil }), do: {:error, %{ source: "email", code: :required, title: "Email can't be blank" }}
  def get_jwt(%{ password: nil }), do: {:error, %{ source: "password", code: :required, title: "Password can't be blank" }}
  def get_jwt(%{ email: email, password: password }) do
    with {:ok, user} <- get_user(email),
         true <- Comeonin.Bcrypt.checkpw(password, user.encrypted_password),
         jwt <- Repo.get_by!(Jwt, user_id: user.id, system_tag: "default")
    do
      {:ok, jwt}
    else
      false -> {:error, %{ code: :invalid, title: "Email or password does not match" }}
      {:error, :not_found} -> {:error, %{ code: :invalid, title: "Email or password does not match" }}
    end
  end
  def get_jwt(_params), do: {:error, %{ code: :required, title: "You must provide email and password" }}

  def get_user(email) do
    user = Repo.get_by(User, email: email)

    if user do
      {:ok, user}
    else
      {:error, :not_found}
    end
  end
end
