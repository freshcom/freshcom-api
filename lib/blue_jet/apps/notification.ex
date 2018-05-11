defmodule BlueJet.Notification do
  use BlueJet, :context

  def list_trigger(req), do: list("trigger", req)
  def create_trigger(req), do: create("trigger", req)
  def get_trigger(req), do: get("trigger", req)
  def update_trigger(req), do: update("trigger", req)
  def delete_trigger(req), do: delete("trigger", req)

  def list_email(req), do: list("email", req)
  def get_email(req), do: get("email", req)

  def list_email_template(req), do: list("email_template", req)
  def create_email_template(req), do: create("email_template", req)
  def get_email_template(req), do: get("email_template", req)
  def update_email_template(req), do: update("email_template", req)
  def delete_email_template(req), do: delete("email_template", req)

  def list_sms(req), do: list("sms", req)
  def get_sms(req), do: get("sms", req)

  def list_sms_template(req), do: list("sms_template", req)
  def create_sms_template(req), do: create("sms_template", req)
  def get_sms_template(req), do: get("sms_template", req)
  def update_sms_template(req), do: update("sms_template", req)
  def delete_sms_template(req), do: delete("sms_template", req)
end
