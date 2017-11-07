defmodule BlueJet.Identity.Jwt do

  def sign_token(claims) do
    {_, signed} = System.get_env("JWT_PRIVATE_KEY")
                 |> JOSE.JWK.from_pem
                 |> JOSE.JWT.sign(%{ "alg" => "RS256" }, claims)
                 |> JOSE.JWS.compact
    signed
  end

  def verify_token(signed_token) do
    with {true, %JOSE.JWT{ fields: claims }, _} <- JOSE.JWK.from_pem(System.get_env("JWT_PUBLIC_KEY")) |> JOSE.JWT.verify_strict(["RS256"], signed_token)
    do
      {true, claims}
    else
      {:error, _} -> {false, nil}
    end
  end
end
