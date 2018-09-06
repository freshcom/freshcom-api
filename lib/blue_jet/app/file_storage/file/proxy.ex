defmodule BlueJet.FileStorage.File.Proxy do
  use BlueJet, :proxy

  alias BlueJet.FileStorage.S3Client
  alias BlueJet.FileStorage.File

  def delete_s3_object(file_or_files) do
    File.get_s3_key(file_or_files)
    |> S3Client.delete_object()
  end
end
