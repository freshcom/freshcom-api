defmodule BlueJet.Notification.Policy do
  use BlueJet, :policy

  #
  # MARK: Trigger
  #
  def authorize(request = %{role: role}, "list_trigger")
      when role in ["developer", "administrator"] do
    {:ok, from_access_request(request, :list)}
  end

  def authorize(request = %{role: role}, "create_trigger")
      when role in ["developer", "administrator"] do
    {:ok, from_access_request(request, :create)}
  end

  def authorize(request = %{role: role}, "get_trigger")
      when role in ["developer", "administrator"] do
    {:ok, from_access_request(request, :get)}
  end

  def authorize(request = %{role: role}, "update_trigger")
      when role in ["developer", "administrator"] do
    {:ok, from_access_request(request, :update)}
  end

  def authorize(request = %{role: role}, "delete_trigger")
      when role in ["developer", "administrator"] do
    {:ok, from_access_request(request, :delete)}
  end

  #
  # MARK: Email
  #
  def authorize(request = %{role: role}, "list_email")
      when role in ["support_specialist", "developer", "administrator"] do
    {:ok, from_access_request(request, :list)}
  end

  def authorize(request = %{role: role}, "get_email")
      when role in ["support_specialist", "developer", "administrator"] do
    {:ok, from_access_request(request, :get)}
  end

  #
  # MARK: Email Template
  #
  def authorize(request = %{role: role}, "list_email_template")
      when role in ["developer", "administrator"] do
    {:ok, from_access_request(request, :list)}
  end

  def authorize(request = %{role: role}, "create_email_template")
      when role in ["developer", "administrator"] do
    {:ok, from_access_request(request, :create)}
  end

  def authorize(request = %{role: role}, "get_email_template")
      when role in ["developer", "administrator"] do
    {:ok, from_access_request(request, :get)}
  end

  def authorize(request = %{role: role}, "update_email_template")
      when role in ["developer", "administrator"] do
    {:ok, from_access_request(request, :update)}
  end

  def authorize(request = %{role: role}, "delete_email_template")
      when role in ["developer", "administrator"] do
    {:ok, from_access_request(request, :delete)}
  end

  #
  # MARK: SMS
  #
  def authorize(request = %{role: role}, "list_sms")
      when role in ["support_specialist", "developer", "administrator"] do
    {:ok, from_access_request(request, :list)}
  end

  def authorize(request = %{role: role}, "get_sms")
      when role in ["support_specialist", "developer", "administrator"] do
    {:ok, from_access_request(request, :get)}
  end

  #
  # MARK: SMS Template
  #
  def authorize(request = %{role: role}, "list_sms_template")
      when role in ["developer", "administrator"] do
    {:ok, from_access_request(request, :list)}
  end

  def authorize(request = %{role: role}, "create_sms_template")
      when role in ["developer", "administrator"] do
    {:ok, from_access_request(request, :create)}
  end

  def authorize(request = %{role: role}, "get_sms_template")
      when role in ["developer", "administrator"] do
    {:ok, from_access_request(request, :get)}
  end

  def authorize(request = %{role: role}, "update_sms_template")
      when role in ["developer", "administrator"] do
    {:ok, from_access_request(request, :update)}
  end

  def authorize(request = %{role: role}, "delete_sms_template")
      when role in ["developer", "administrator"] do
    {:ok, from_access_request(request, :delete)}
  end

  #
  # MARK: Other
  #
  def authorize(_, _) do
    {:error, :access_denied}
  end
end
