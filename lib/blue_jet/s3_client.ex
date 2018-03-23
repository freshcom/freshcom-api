defmodule BlueJet.S3.Client do
  def get_presigned_url(key, :get) do
    config = ExAws.Config.new(:s3)

    if System.get_env("CDN_HOST") && String.length(System.get_env("CDN_HOST")) > 0 do
      expires_in = 3600
      host = System.get_env("CDN_HOST")
      url = "https://#{host}/#{key}"
      datetime = :calendar.universal_time
      {:ok, url} = ExAws.Auth.presigned_url(:get, url, :cloudfront, datetime, config, expires_in, [])

      url
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