defmodule BlueJet.Notification.Trigger.Factory do
  alias BlueJet.Notification.Trigger

  def send_password_reset_email(account, email_template) do
    %Trigger{
      account_id: account.id,
      system_label: "default",
      name: "Send password reset email",
      event: "identity:password_reset_token.create.success",
      action_type: "send_email",
      action_target: email_template.id
    }
  end

  def send_password_reset_not_registered_email(account, email_template) do
    %Trigger{
      account_id: account.id,
      system_label: "default",
      name: "Send password reset not registered email",
      event: "identity:password_reset_token.create.error.username_not_found",
      action_type: "send_email",
      action_target: email_template.id
    }
  end

  def send_email_verification_email(account, email_template) do
    %Trigger{
      account_id: account.id,
      system_label: "default",
      name: "Send email verification email",
      event: "identity:email_verification_token.create.success",
      action_type: "send_email",
      action_target: email_template.id
    }
  end

  def send_order_confirmation_email(account, email_template) do
    %Trigger{
      account_id: account.id,
      system_label: "default",
      name: "Send order confirmation email",
      event: "storefront.order.opened.success",
      action_type: "send_email",
      action_target: email_template.id
    }
  end

  def send_phone_verification_sms(account, sms_template) do
    %Trigger{
      account_id: account.id,
      system_label: "default",
      name: "Send phone verification sms",
      event: "identity:phone_verification_code.create.success",
      action_type: "send_sms",
      action_target: sms_template.id
    }
  end

  def send_tfa_sms(account, sms_template) do
    %Trigger{
      account_id: account.id,
      system_label: "default",
      name: "Send TFA sms",
      event: "identity:user.tfa_code.create.success",
      action_type: "send_sms",
      action_target: sms_template.id
    }
  end
end