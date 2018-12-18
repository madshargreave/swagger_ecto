defmodule SwaggerEcto.Schema do
  @moduledoc """
  Schema definition for Ecto and Swagger
  """

  @doc false
  defmacro __using__(_opts) do
    quote do
      use Ecto.Schema
      import SwaggerEcto.Schema
    end
  end

  @doc """
  Defines and Ecto schema
  """
  defmacro swagger_schema(source, block) do
    quote do
      Ecto.Schema.schema unquote(source), unquote(block)
      SwaggerEcto.Schema.define_schema unquote(source), unquote(block)
    end
  end

  defmacro swagger_embedded_schema(source, block) do
    quote do
      Ecto.Schema.embedded_schema unquote(block)
      SwaggerEcto.Schema.define_embedded_schema unquote(source), unquote(block)
    end
  end

  @doc false
  defmacro define_schema(source, block) do
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

  @doc false
  defmacro define_embedded_schema(source, block) do
    exprs =
      case block do
        [do: {:__block__, _, exprs}] -> exprs
        [do: expr] when is_tuple(expr) -> [expr]
      end

    schema = SwaggerEcto.Helpers.create_schema(source, exprs)
    escaped = Macro.escape(schema)
    quote do
      def __schema__(:swagger) do
        schema = unquote(escaped)
        PhoenixSwagger.to_json(schema)
      end
    end
  end

end
