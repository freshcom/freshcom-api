defmodule BlueJet.Notification.Policy do
  alias BlueJet.AccessRequest
  alias BlueJet.Notification.IdentityService

  #
  # MARK: Trigger
  #
  def authorize(request = %{ role: role }, "list_trigger") when role in ["developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :list)}
  end

  def authorize(request = %{ role: role }, "create_trigger") when role in ["developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :create)}
  end

  def authorize(request = %{ role: role }, "get_trigger") when role in ["developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :get)}
  end

  def authorize(request = %{ role: role }, "update_trigger") when role in ["developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :update)}
  end

  def authorize(request = %{ role: role }, "delete_trigger") when role in ["developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :delete)}
  end

  #
  # MARK: Email
  #
  def authorize(request = %{ role: role }, "list_email") when role in ["support_specialist", "developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :list)}
  end

  def authorize(request = %{ role: role }, "get_email") when role in ["support_specialist", "developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :get)}
  end

  #
  # MARK: Email Template
  #
  def authorize(request = %{ role: role }, "list_email_template") when role in ["developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :list)}
  end

  def authorize(request = %{ role: role }, "create_email_template") when role in ["developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :create)}
  end

  def authorize(request = %{ role: role }, "get_email_template") when role in ["developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :get)}
  end

  def authorize(request = %{ role: role }, "update_email_template") when role in ["developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :update)}
  end

  def authorize(request = %{ role: role }, "delete_email_template") when role in ["developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :delete)}
  end

  #
  # MARK: SMS
  #
  def authorize(request = %{ role: role }, "list_sms") when role in ["support_specialist", "developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :list)}
  end

  def authorize(request = %{ role: role }, "get_sms") when role in ["support_specialist", "developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :get)}
  end

  #
  # MARK: SMS Template
  #
  def authorize(request = %{ role: role }, "list_sms_template") when role in ["developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :list)}
  end

  def authorize(request = %{ role: role }, "create_sms_template") when role in ["developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :create)}
  end

  def authorize(request = %{ role: role }, "get_sms_template") when role in ["developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :get)}
  end

  def authorize(request = %{ role: role }, "update_sms_template") when role in ["developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :update)}
  end

  def authorize(request = %{ role: role }, "delete_sms_template") when role in ["developer", "administrator"] do
    {:ok, AccessRequest.to_authorized_args(request, :delete)}
  end

  #
  # MARK: Other
  #
  def authorize(request = %{ role: nil }, endpoint) do
    request
    |> IdentityService.put_vas_data()
    |> authorize(endpoint)
  end

  def authorize(_, _) do
    {:error, :access_denied}
  end
end
