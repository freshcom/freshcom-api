defmodule BlueJet.Notification.Policy do
  use BlueJet, :policy

  # TODO: Fix this
  def authorize(%{vas: vas, _role_: nil} = req, endpoint) do
    identity_service =
      Atom.to_string(__MODULE__)
      |> String.split(".")
      |> Enum.drop(-1)
      |> Enum.join(".")
      |> Module.concat(IdentityService)

    vad = identity_service.get_vad(vas)
    role = identity_service.get_role(vad)
    default_locale = if vad[:account], do: vad[:account].default_locale, else: nil

    req
    |> Map.put(:_vad_, vad)
    |> Map.put(:_role_, role)
    |> Map.put(:_default_locale_, default_locale)
    |> authorize(endpoint)
  end

  #
  # MARK: Trigger
  #
  def authorize(%{_role_: role} = req, :list_trigger)
      when role in ["developer", "administrator"] do
    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :create_trigger)
      when role in ["developer", "administrator"] do
    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :get_trigger)
      when role in ["developer", "administrator"] do
    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :update_trigger)
      when role in ["developer", "administrator"] do
    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :delete_trigger)
      when role in ["developer", "administrator"] do
    {:ok, req}
  end

  #
  # MARK: Email
  #
  def authorize(%{_role_: role} = req, :list_email)
      when role in ["support_specialist", "developer", "administrator"] do
    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :get_email)
      when role in ["support_specialist", "developer", "administrator"] do
    {:ok, req}
  end

  #
  # MARK: Email Template
  #
  def authorize(%{_role_: role} = req, :list_email_template)
      when role in ["developer", "administrator"] do
    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :create_email_template)
      when role in ["developer", "administrator"] do
    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :get_email_template)
      when role in ["developer", "administrator"] do
    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :update_email_template)
      when role in ["developer", "administrator"] do
    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :delete_email_template)
      when role in ["developer", "administrator"] do
    {:ok, req}
  end

  #
  # MARK: SMS
  #
  def authorize(%{_role_: role} = req, :list_sms)
      when role in ["support_specialist", "developer", "administrator"] do
    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :get_sms)
      when role in ["support_specialist", "developer", "administrator"] do
    {:ok, req}
  end

  #
  # MARK: SMS Template
  #
  def authorize(%{_role_: role} = req, :list_sms_template)
      when role in ["developer", "administrator"] do
    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :create_sms_template)
      when role in ["developer", "administrator"] do
    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :get_sms_template)
      when role in ["developer", "administrator"] do
    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :update_sms_template)
      when role in ["developer", "administrator"] do
    {:ok, req}
  end

  def authorize(%{_role_: role} = req, :delete_sms_template)
      when role in ["developer", "administrator"] do
    {:ok, req}
  end

  #
  # MARK: Other
  #
  def authorize(_, _) do
    {:error, :access_denied}
  end
end
