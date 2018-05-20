defmodule BlueJet.Query.Preloads do
  def preloads do
    quote do
      def preloads(targets) when is_list(targets) and length(targets) == 0 do
        []
      end

      def preloads(targets) when is_list(targets) do
        [target | rest] = targets
        preloads(target) ++ preloads(rest)
      end

      def preloads(targets, _) when is_list(targets) and length(targets) == 0 do
        []
      end

      def preloads(targets, options) when is_list(targets) do
        [target | rest] = targets
        preloads(target, options) ++ preloads(rest, options)
      end

      def preloads(target, options) when is_atom(target) do
        preloads({target, nil}, options)
      end

      def preloads({nil, nil}, _) do
        []
      end
    end
  end

  defmacro __using__(_) do
    preloads()
  end
end