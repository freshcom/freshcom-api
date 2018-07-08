defmodule BlueJetWeb.ErrorView do
  use BlueJetWeb, :view

  def render("400.json-api", %{reason: %Plug.Parsers.ParseError{exception: %Poison.SyntaxError{}}}) do
    %{
      errors: [%{
        code: "invalid_json",
        title: "Invalid JSON",
        detail: "The request body is not in valid JSON format."
      }]
    }
  end

  def render("400.json-api", %{reason: %Phoenix.MissingParamError{}}) do
    %{
      errors: [%{
        code: "missing_required_fields",
        title: "Missing Required Fields",
        detail: "The top level of request body must include a \"data\" field or a \"meta\" field."
      }]
    }
  end

  def render("400.json-api", %{reason: %Phoenix.ActionClauseError{}}) do
    %{
      errors: [%{
        code: "missing_type",
        title: "Missing Type",
        detail: "The \"data.type\" field of your request body is missing."
      }]
    }
  end

  def render("404.json-api", %{reason: %Phoenix.Router.NoRouteError{}}) do
    %{
      errors: [%{
        code: "invalid_endpoint",
        title: "Invalid Endpoint",
        detail: "The endpoint you are trying to access does not exist."
      }]
    }
  end

  def render("404.json-api", _) do
    %{
      errors: [%{
        code: "not_found",
        title: "Not Found",
        detail: "The resource you are trying to access does not exist."
      }]
    }
  end

  def render("403.json-api", _) do
    %{
      errors: [%{
        code: "access_denied",
        title: "Access Denied",
        detail: "You do not permission to perform such action."
      }]
    }
  end

  def render("500.json-api", _) do
    %{
      errors: [%{
        code: "unkown_error",
        title: "Unkown Error",
        detail: "An unkown error has occurred, there is nothing you can do to fix this error. " <>
                "Sorry for any inconvenience. " <>
                "Our engineering team has been notified, please give us some time to fix this error. " <>
                "Thank you for your understanding."
      }]
    }
  end

  # In case no render clause matches or no
  # template is found, let's render it as 500
  def template_not_found(_template, assigns) do
    render "500.json-api", assigns
  end
end
