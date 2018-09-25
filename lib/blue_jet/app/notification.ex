defmodule BlueJet.Notification do
  use BlueJet, :context

  alias BlueJet.Notification.{Policy, Service}

  def list_trigger(req), do: default(req, :list, :trigger, Policy, Service)
  def create_trigger(req), do: default(req, :create, :trigger, Policy, Service)
  def get_trigger(req), do: default(req, :get, :trigger, Policy, Service)
  def update_trigger(req), do: default(req, :update, :trigger, Policy, Service)
  def delete_trigger(req), do: default(req, :delete, :trigger, Policy, Service)

  def list_email(req), do: default(req, :list, :email, Policy, Service)
  def get_email(req), do: default(req, :get, :email, Policy, Service)

  def list_email_template(req), do: default(req, :list, :email_template, Policy, Service)
  def create_email_template(req), do: default(req, :create, :email_template, Policy, Service)
  def get_email_template(req), do: default(req, :get, :email_template, Policy, Service)
  def update_email_template(req), do: default(req, :update, :email_template, Policy, Service)
  def delete_email_template(req), do: default(req, :delete, :email_template, Policy, Service)

  def list_sms(req), do: default(req, :list, :sms, Policy, Service)
  def get_sms(req), do: default(req, :get, :sms, Policy, Service)

  def list_sms_template(req), do: default(req, :list, :sms_template, Policy, Service)
  def create_sms_template(req), do: default(req, :create, :sms_template, Policy, Service)
  def get_sms_template(req), do: default(req, :get, :sms_template, Policy, Service)
  def update_sms_template(req), do: default(req, :update, :sms_template, Policy, Service)
  def delete_sms_template(req), do: default(req, :delete, :sms_template, Policy, Service)
end
