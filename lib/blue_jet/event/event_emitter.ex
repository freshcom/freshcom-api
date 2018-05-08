defmodule BlueJet.EventEmitter do
  def event_emitter(namespace) do
    quote do
      def emit_event(name, data) do
        listeners = Map.get(Application.get_env(:blue_jet, unquote(namespace), %{}), :listeners, [])

        Enum.reduce_while(listeners, {:ok, []}, fn(listener, acc) ->
          with {:ok, result} <- listener.handle_event(name, data) do
            {:ok, acc_result} = acc
            {:cont, {:ok, acc_result ++ [{listener, result}]}}
          else
            {:error, errors} -> {:halt, {:error, errors}}
            other -> {:halt, other}
          end
        end)
      end
    end
  end

  defmacro __using__(namespace: namespace) do
    event_emitter(namespace)
  end
end