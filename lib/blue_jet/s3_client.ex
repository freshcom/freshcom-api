defmodule BlueJet.S3.Client do
  def build_cdn_url(s3_key) do
    host = System.get_env("CDN_HOST")
    "https://#{host}/#{s3_key}"
  end

  def build_policy(url, expiry_time) do
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

  def sign(policy) do
    private_pem = System.get_env("CLOUDFRONT_PRIVATE_KEY")
    [private_entry] = :public_key.pem_decode(private_pem)
    key = :public_key.pem_entry_decode(private_entry)

    policy
    |> :public_key.sign(:sha, key)
    |> Base.encode64(padding: false)
    |> String.replace("+", "-")
    |> String.replace("=", "_")
    |> String.replace("/", "~")
  end

  def get_presigned_url(key, :get) do
    config = ExAws.Config.new(:s3)

    if System.get_env("CDN_HOST") && String.length(System.get_env("CDN_HOST")) > 0 do
      url = build_cdn_url(key)
      expires = :os.system_time(:seconds) + 3600

      policy = build_policy(url, expires)
      signature = sign(policy)
      key_pair_id = System.get_env("CLOUDFRONT_ACCESS_KEY_ID")

      "#{url}?Expires=#{expires}&Signature=#{signature}&Key-Pair-Id=#{key_pair_id}"
    else
      {:ok, url} = ExAws.S3.presigned_url(config, :get, System.get_env("AWS_S3_BUCKET_NAME"), key)

      url
    end
  end

  def get_presigned_url(key, method) do
    config = ExAws.Config.new(:s3)
    {:ok, url} = ExAws.S3.presigned_url(config, method, System.get_env("AWS_S3_BUCKET_NAME"), key)

    url
  end

  def delete_object(keys) when is_list(keys) do
    ExAws.S3.delete_all_objects(System.get_env("AWS_S3_BUCKET_NAME"), keys)
    |> ExAws.request()

    :ok
  end

  def delete_object(key) do
    ExAws.S3.delete_object(System.get_env("AWS_S3_BUCKET_NAME"), key)
    |> ExAws.request()

    :ok
  end
end