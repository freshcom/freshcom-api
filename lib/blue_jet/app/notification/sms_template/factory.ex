defmodule BlueJet.Notification.SmsTemplate.Factory do
  alias BlueJet.Notification.SmsTemplate

  def phone_verification(account) do
    %SmsTemplate{
      account_id: account.id,
      system_label: "default",
      name: "Phone Verification Code",
      to: "{{phone_number}}",
      body: "Your {{account.name}} verification code: {{code}}"
    }
  end

  def tfa(account) do
    %SmsTemplate{
      account_id: account.id,
      system_label: "default",
      name: "TFA Code",
      to: "{{user.phone_number}}",
      body: "Your {{account.name}} verification code: {{code}}"
    }
  end
end