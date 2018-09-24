defmodule BlueJet.Notification.EmailTemplate.Factory do
  alias BlueJet.Notification.EmailTemplate

  def password_reset(account) do
    password_reset_html =
      File.read!("lib/blue_jet/app/notification/email_templates/password_reset.html")

    password_reset_text =
      File.read!("lib/blue_jet/app/notification/email_templates/password_reset.txt")

    %EmailTemplate{
      account_id: account.id,
      system_label: "default",
      name: "Password Reset",
      subject: "Reset your password for {{account.name}}",
      to: "{{user.email}}",
      body_html: password_reset_html,
      body_text: password_reset_text
    }
  end

  def password_reset_not_registered(account) do
    password_reset_not_registered_html =
      File.read!(
        "lib/blue_jet/app/notification/email_templates/password_reset_not_registered.html"
      )

    password_reset_not_registered_text =
      File.read!(
        "lib/blue_jet/app/notification/email_templates/password_reset_not_registered.txt"
      )

    %EmailTemplate{
      account_id: account.id,
      system_label: "default",
      name: "Password Reset Not Registered",
      subject: "Reset password attempt for {{account.name}}",
      to: "{{email}}",
      body_html: password_reset_not_registered_html,
      body_text: password_reset_not_registered_text
    }
  end

  def email_verification(account) do
    email_verification_html =
      File.read!("lib/blue_jet/app/notification/email_templates/email_verification.html")

    email_verification_text =
      File.read!("lib/blue_jet/app/notification/email_templates/email_verification.txt")

    %EmailTemplate{
      account_id: account.id,
      system_label: "default",
      name: "Email Verification",
      subject: "Verify your email for {{account.name}}",
      to: "{{user.email}}",
      body_html: email_verification_html,
      body_text: email_verification_text
    }
  end

  def order_confirmation(account) do
    order_confirmation_html =
      File.read!("lib/blue_jet/app/notification/email_templates/order_confirmation.html")

    order_confirmation_text =
      File.read!("lib/blue_jet/app/notification/email_templates/order_confirmation.txt")

    %EmailTemplate{
      account_id: account.id,
      system_label: "default",
      name: "Order Confirmation",
      subject: "Your order is confirmed",
      to: "{{order.email}}",
      body_html: order_confirmation_html,
      body_text: order_confirmation_text
    }
  end
end