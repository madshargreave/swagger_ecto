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
        [do: {:__block__, _, exprs}] ->
          exprs
        [do: expr] when is_tuple(expr) ->
          [expr]
      end

    schema = SwaggerEcto.Helpers.create_schema(source, exprs, __CALLER__) |> Macro.escape
    schema_list = SwaggerEcto.Helpers.create_schema_list(source, exprs, __CALLER__) |> Macro.escape
    quote do
      {id, type, opts} = Module.get_attribute(__MODULE__, :primary_key)

      @primary_key_field id
      @primary_key_type type
      @primary_key_opts opts

      def __swagger__, do: __swagger__(:single)
      def __swagger__(:single) do
        schema = unquote(schema)
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
      def __swagger__(:list) do
        unquote(schema_list)
        |> PhoenixSwagger.to_json
      end
      def __swagger__(:name) do
        unquote(source)
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

    schema = SwaggerEcto.Helpers.create_schema(source, exprs, __CALLER__) |> Macro.escape
    schema_list = SwaggerEcto.Helpers.create_schema_list(source, exprs, __CALLER__) |> Macro.escape
    quote do
      def __swagger__, do: __swagger__(:single)
      def __swagger__(:single) do
        schema = unquote(schema)
        PhoenixSwagger.to_json(schema)
      end
      def __swagger__(:list) do
        schema = unquote(schema_list)
        PhoenixSwagger.to_json(schema)
      end
      def __swagger__(:name) do
        unquote(source)
      end
    end
  end

end
