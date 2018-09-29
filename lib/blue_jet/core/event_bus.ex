defmodule BlueJet.EventBus do
  @subscribers Application.get_env(:blue_jet, :event_bus, %{})

  def dispatch(name, data, opts \\ [])

  def dispatch(_, _, skip: true), do: {:ok, :skipped}

  def dispatch(name, data, force_ok: true) do
    case dispatch(name, data) do
      {:error, _} -> {:ok, nil}
      other -> other
    end
  end

  def dispatch(name, data, _) do
    subscribers = (@subscribers[name] || []) ++ (@subscribers["*"] || [])

    Enum.reduce_while(subscribers, {:ok, []}, fn(subscriber, acc) ->
      with {:ok, result} <- subscriber.handle_event(name, data) do
        {:ok, acc_result} = acc
        {:cont, {:ok, acc_result ++ [{subscriber, result}]}}
      else
        {:error, errors} -> {:halt, {:error, errors}}
        other -> {:halt, other}
      end
    end)
  end
end