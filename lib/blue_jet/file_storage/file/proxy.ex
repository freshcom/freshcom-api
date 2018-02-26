defmodule BlueJet.FileStorage.File.Proxy do
  use BlueJet, :proxy

  alias BlueJet.FileStorage.IdentityService
  alias BlueJet.FileStorage.S3Client

  alias BlueJet.FileStorage.File

  def get_account(file) do
    file.account || IdentityService.get_account(file)
  end

  def delete_s3_object(file) do
    File.get_s3_key(file)
    |> S3Client.delete_object()
  end
end