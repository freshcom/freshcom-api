defmodule BlueJet.Proxy.Common do
  def common do
    quote do
      def put(nil, _, _), do: nil

      def put(struct_or_structs, targets, options) when is_list(targets) and length(targets) == 0 do
        struct_or_structs
      end

      def put(structs, targets, options) when is_list(structs) do
        Enum.map(structs, fn(struct) ->
          put(struct, targets, options)
        end)
      end

      def put(struct, targets, options) when is_list(targets) do
        [target | rest] = targets

        struct
        |> put(target, options)
        |> put(rest, options)
      end

      def put(struct, target, options) when is_atom(target) do
        put(struct, {target, nil}, options)
      end
    end
  end

  defmacro __using__(_) do
    common()
  end
end