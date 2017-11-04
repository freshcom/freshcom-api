defmodule BlueJet.Authorization.PermissionProvider do
  @callback permission(module) :: map

  def permission!(implementation) do
    implementation.permission()
  end
end