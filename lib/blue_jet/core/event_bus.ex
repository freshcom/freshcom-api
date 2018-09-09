defmodule BlueJet.EventBus do
  @subscribers Application.get_env(:blue_jet, :event_bus, %{})

  def dispatch(name, data) do
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