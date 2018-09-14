defmodule BlueJet.ControlFlow do
  def tt({:ok, any}), do: {:ok, any}
  def tt({:error, error}), do: {:ok, error}
  def tt(nil), do: {:error, nil}
  def tt(:error), do: {:error, :error}
  def tt(any), do: {:ok, any}

  def map({:ok, value}, fun) when is_function(fun, 1) do
    case fun.(value) do
      nil -> {:error, nil}
      other -> {:ok, other}
    end
  end

  def map({:error, reason}, _), do: {:error, reason}

  def flat_map({:ok, value}, fun) when is_function(fun, 1), do: fun.(value)
  def flat_map({:error, reason}, _), do: {:error, reason}

  defmacro lhs ~> {call, line, args} do
    value = quote do: value
    args = [value | args || []]

    quote do
      BlueJet.ControlFlow.map(unquote(lhs), fn unquote(value) -> unquote({call, line, args}) end)
    end
  end

  defmacro lhs ~>> {call, line, args} do
    value = quote do: value
    args = [value | args || []]

    quote do
      BlueJet.ControlFlow.flat_map(unquote(lhs), fn unquote(value) -> unquote({call, line, args}) end)
    end
  end
end