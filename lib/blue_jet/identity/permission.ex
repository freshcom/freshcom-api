defmodule BlueJet.Identity.Permission do

  def default(:administrator) do
    %{ "*" => "*" }
  end

  def default(:developer) do
    %{}
  end

  def default(:support_personnel) do
    %{}
  end

  def default(:customer) do
    %{}
  end
end