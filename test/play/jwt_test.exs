# defmodule BlueJet.RefreshTokenText do
#   use BlueJet.ModelCase
#   import Joken

#   describe "Key" do
#     test "with valid attributes" do
#       private_key = JOSE.JWK.from_pem(System.get_env("JWT_PRIVATE_KEY"))
#       public_key = JOSE.JWK.from_pem(System.get_env("JWT_PUBLIC_KEY"))

#       # signed_token = %{ "name" => "John XXX" }
#       # |> token
#       # |> sign(rs256(private_key))
#       # |> get_compact

#       # IO.inspect signed_token

#       # JSON Web Key (JWK)
#       jwk = %{
#         "kty" => "oct",
#         "k" => :base64url.encode("symmetric key")
#       }

#       # JSON Web Signature (JWS)
#       jws = %{
#         "alg" => "RS256"
#       }

#       # JSON Web Token (JWT)
#       jwt = %{
#         "iss" => "joe",
#         "exp" => 1300819380,
#         "http://example.com/is_root" => true
#       }

#       xx = JOSE.JWT.sign(private_key, jws, jwt)
#       {_, zz} = JOSE.JWS.compact(xx)
#       IO.inspect zz

#       vv = JOSE.JWT.verify_strict(public_key, ["RS256"], zz)
#       IO.inspect vv

#       # verified_token = signed_token
#       # |> token
#       # |> with_signer(rs256(public_key))
#       # |> verify

#       # IO.inspect verified_token
#     end
#   end
# end
