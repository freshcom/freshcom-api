defmodule BlueJet.FileStorage.CloudfrontClient do
  @moduledoc false

  @cloudfront_client Application.get_env(:blue_jet, :file_storage)[:cloudfront_client]

  @callback get_presigned_url(String.t()) :: String.t()

  defdelegate get_presigned_url(key), to: @cloudfront_client
end
