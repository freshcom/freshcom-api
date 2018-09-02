defmodule BlueJet.FileStorage.S3Client do
  @s3_client Application.get_env(:blue_jet, :file_storage)[:s3_client]

  @callback get_presigned_url(String.t(), String.t()) :: String.t()
  @callback delete_object(String.t() | [String.t()]) :: :ok

  defdelegate get_presigned_url(key, method), to: @s3_client
  defdelegate delete_object(key), to: @s3_client
end
