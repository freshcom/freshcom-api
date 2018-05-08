defmodule BlueJet.Cloudfront.Client do
  def get_url(key) do
    cdn_root_url = System.get_env("CDN_ROOT_URL")
    "#{cdn_root_url}/#{key}"
  end

  def get_policy(url, expiry_time) do
    Poison.encode!(%{
       "Statement" => [
          %{
             "Resource" => url,
             "Condition" => %{
                "DateLessThan" => %{
                   "AWS:EpochTime" => expiry_time
                }
             }
          }
       ]
    })
  end

  def get_signature(policy) do
    pem = System.get_env("CLOUDFRONT_PRIVATE_KEY")
    key = get_cloudfront_private_key(pem)

    policy
    |> :public_key.sign(:sha, key)
    |> Base.encode64()
    |> String.replace("+", "-")
    |> String.replace("=", "_")
    |> String.replace("/", "~")
  end

  def get_policy_signature(url, expiry_time) do
    get_policy(url, expiry_time)
    |> get_signature()
  end

  def get_cloudfront_private_key(pem) do
    [private_entry] = :public_key.pem_decode(pem)
    :public_key.pem_entry_decode(private_entry)
  end

  def get_presigned_url(key) do
    url = get_url(key)
    expires = :os.system_time(:seconds) + 3600
    signature = get_policy_signature(url, expires)
    key_pair_id = System.get_env("CLOUDFRONT_ACCESS_KEY_ID")

    "#{url}?Expires=#{expires}&Signature=#{signature}&Key-Pair-Id=#{key_pair_id}"
  end
end