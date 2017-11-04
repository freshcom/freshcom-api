defmodule BlueJet.Authorization do
  use BlueJet, :context

  alias Ecto.Changeset
  alias BlueJet.Authorization.Role
  alias BlueJet.Authorization.RoleInstance

  def list_permissions(request) do
    # %{
    #   "storefront.list_orders" => %{
    #     "scope" => %{
    #       "order_owned_by_user": %{},
    #       "created_at_gt": %{ "date":  }
    #     },
    #     "endpoint" => %{
    #       "request" => %{
    #         "url_params": [""]
    #         "query_params": [""]
    #         "ids" => [""]
    #         "attribute_keys" => [""],
    #         "relationship_keys" => [""],
    #         "meta_keys" => [""]
    #       },
    #       "response" => %{
    #         "attribute_keys" => [""],
    #         "relationship_keys" => [""],
    #         "meta_keys" => [""]
    #       }
    #     }
    #   }
    # }
  end
end
