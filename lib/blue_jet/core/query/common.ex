defmodule BlueJet.Query.Common do
  def common do
    quote do
      def for_account(query, account_id) do
        from q in query, where: q.account_id == ^account_id
      end

      def order_by(query, order) do
        from q in query, order_by: ^order
      end

      def paginate(query, size: size, number: number) do
        limit = size
        offset = size * (number - 1)

        query
        |> limit(^limit)
        |> offset(^offset)
      end

      def id_only(query) do
        from r in query, select: r.id
      end
    end
  end

  defmacro __using__(_) do
    common()
  end
end