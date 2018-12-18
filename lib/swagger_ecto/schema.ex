defmodule SwaggerEcto.Schema do
  @moduledoc """
  Schema definition for Ecto and Swagger
  """

  @doc false
  defmacro __using__(_opts) do
    quote do
      use Ecto.Schema
      import Ecto.Schema
      import SwaggerEcto.Schema
      import SwaggerEcto.Helpers
      @before_compile SwaggerEcto.Schema
    end
  end

  @doc false
  defmacro __before_compile__(_env) do
    quote do

    end
  end

  @doc """
  Defines and Ecto schema
  """
  defmacro swagger_schema(source, block) do
    quote do
      Ecto.Schema.schema unquote(source), unquote(block)
      SwaggerEcto.Schema.schema unquote(source), unquote(block)
    end
  end

  @doc false
  defmacro schema(source, block) do
    exprs =
      case block do
        [do: {:__block__, _, exprs}] -> exprs
        [do: expr] when is_tuple(expr) -> [expr]
      end

    schema = SwaggerEcto.Helpers.create_schema(source, exprs)
    escaped = Macro.escape(schema)
    quote do
      {id, type, opts} = Module.get_attribute(__MODULE__, :primary_key)

      @primary_key_field id
      @primary_key_type type
      @primary_key_opts opts

      def __schema__(:swagger) do
        schema = unquote(escaped)
        id_type = if @primary_key_type == :id, do: :integer, else: :string

        %{schema |
          required: [@primary_key_field | schema.required],
          properties: Map.merge(schema.properties, %{
            @primary_key_field => %{
              type: id_type
            }
          })
        }
        |> PhoenixSwagger.to_json
      end
    end
  end

end
