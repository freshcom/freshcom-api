defmodule BlueJet.Notification.Service do
  @service Application.get_env(:blue_jet, :notification)[:service]

  @callback list_trigger(map, map) :: [Trigger.t()]
  @callback count_trigger(map, map) :: integer
  @callback create_trigger(map, map) :: {:ok, Trigger.t()} | {:error, any}
  @callback create_system_default_trigger(map) :: :ok
  @callback get_trigger(map, map) :: Trigger.t() | nil
  @callback update_trigger(String.t() | Trigger.t(), map, map) ::
              {:ok, Trigger.t()} | {:error, any}
  @callback delete_trigger(String.t() | Trigger.t(), map) :: {:ok, Trigger.t()} | {:error, any}
  @callback delete_all_trigger(map) :: :ok

  @callback list_email(map, map) :: [Email.t()]
  @callback count_email(map, map) :: integer
  @callback get_email(map, map) :: Email.t() | nil
  @callback delete_all_email(map) :: :ok

  @callback list_email_template(map, map) :: [EmailTemplate.t()]
  @callback count_email_template(map, map) :: integer
  @callback create_email_template(map, map) :: {:ok, EmailTemplate.t()} | {:error, any}
  @callback get_email_template(map, map) :: EmailTemplate.t() | nil
  @callback update_email_template(String.t() | EmailTemplate.t(), map, map) ::
              {:ok, EmailTemplate.t()} | {:error, any}
  @callback delete_email_template(String.t() | EmailTemplate.t(), map) ::
              {:ok, EmailTemplate.t()} | {:error, any}
  @callback delete_all_email_template(map) :: :ok

  @callback list_sms(map, map) :: [Sms.t()]
  @callback count_sms(map, map) :: integer
  @callback get_sms(map, map) :: Sms.t() | nil
  @callback delete_all_sms(map) :: :ok

  @callback list_sms_template(map, map) :: [SmsTemplate.t()]
  @callback count_sms_template(map, map) :: integer
  @callback create_sms_template(map, map) :: {:ok, SmsTemplate.t()} | {:error, any}
  @callback get_sms_template(map, map) :: SmsTemplate.t() | nil
  @callback update_sms_template(String.t() | SmsTemplate.t(), map, map) ::
              {:ok, SmsTemplate.t()} | {:error, any}
  @callback delete_sms_template(String.t() | SmsTemplate.t(), map) ::
              {:ok, SmsTemplate.t()} | {:error, any}
  @callback delete_all_sms_template(map) :: :ok

  defdelegate list_trigger(params, opts), to: @service
  defdelegate count_trigger(params \\ %{}, opts), to: @service
  defdelegate create_trigger(fields, opts), to: @service
  defdelegate create_system_default_trigger(opts), to: @service
  defdelegate get_trigger(identifiers, opts), to: @service
  defdelegate update_trigger(id_or_trigger, fields, opts), to: @service
  defdelegate delete_trigger(id_or_trigger, opts), to: @service
  defdelegate delete_all_trigger(opts), to: @service

  defdelegate list_email(params, opts), to: @service
  defdelegate count_email(params \\ %{}, opts), to: @service
  defdelegate get_email(identifiers, opts), to: @service
  defdelegate delete_all_email(opts), to: @service

  defdelegate list_email_template(params, opts), to: @service
  defdelegate count_email_template(params \\ %{}, opts), to: @service
  defdelegate create_email_template(fields, opts), to: @service
  defdelegate get_email_template(identifiers, opts), to: @service
  defdelegate update_email_template(id_or_email_template, fields, opts), to: @service
  defdelegate delete_email_template(id_or_email_template, opts), to: @service
  defdelegate delete_all_email_template(opts), to: @service

  defdelegate list_sms(params, opts), to: @service
  defdelegate count_sms(params \\ %{}, opts), to: @service
  defdelegate get_sms(identifiers, opts), to: @service
  defdelegate delete_all_sms(opts), to: @service

  defdelegate list_sms_template(params, opts), to: @service
  defdelegate count_sms_template(params \\ %{}, opts), to: @service
  defdelegate create_sms_template(fields, opts), to: @service
  defdelegate get_sms_template(identifiers, opts), to: @service
  defdelegate update_sms_template(id_or_sms_template, fields, opts), to: @service
  defdelegate delete_sms_template(id_or_email_template, opts), to: @service
  defdelegate delete_all_sms_template(opts), to: @service
end
