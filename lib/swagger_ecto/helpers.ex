defmodule SwaggerEcto.Helpers do
  @moduledoc """
  Helpers for defining schemas
  """

  def create_schema(source, exprs) do
    %PhoenixSwagger.Schema{
      title: title(source),
      properties: properties(exprs),
      required: required(exprs)
    }
  end

  def create_schema_list(source, exprs) do
    schema = create_schema(source, exprs)
    %PhoenixSwagger.Schema{
      title: Inflex.pluralize(schema.title),
      type: :array,
      items: PhoenixSwagger.Schema.ref(String.to_atom(schema.title))
    }
  end

  defp title(source) do
    source
    |> Inflex.singularize
    |> Macro.camelize
  end

  defp properties(exprs) do
    exprs
    |> Enum.map(fn expr ->
      case expr do
        {operation, meta, [field, type]} ->
          opts = []
          {operation, meta, [field, type, opts]}
        _ ->
          expr
      end
    end)
    |> Enum.reduce(%PhoenixSwagger.Schema{}, fn expr, acc ->
      value = property(acc, expr)
      Map.merge(acc, value)
    end)
  end

  defp property(schema, {:field, _, [field, raw_type, _opts]}) do
    %{
      field => PhoenixSwagger.Schema.type(%PhoenixSwagger.Schema{}, type(raw_type))
    }
  end

  defp property(schema, {
    op,
    _,
    [
      field,
      {:__aliases__, _, [type]},
      _opts
    ]
  }) when op in [:has_one, :embeds_one, :belongs_to] do
    %{
      field => PhoenixSwagger.Schema.ref(type)
    }
  end

  defp property(schema, {
    op,
    _,
    [
      field,
      {:__aliases__, _, [type]},
      _opts
    ]
  }) when op in [:has_many, :embeds_many] do
    plural_field = Inflex.pluralize(field) |> String.to_atom
    plural_type = Inflex.pluralize(type) |> String.to_atom
    %{
      plural_field => PhoenixSwagger.Schema.ref(plural_type)
    }
  end

  defp property(schema, {:timestamps, _, []}) do
    %{
      inserted_at: PhoenixSwagger.Schema.type(%PhoenixSwagger.Schema{}, :string),
      updated_at: PhoenixSwagger.Schema.type(%PhoenixSwagger.Schema{}, :string)
    }
  end

  defp type(:naive_datetime), do: :string
  defp type(:date), do: :string
  defp type(:map), do: :object
  defp type(type), do: type

  defp required(exprs) do
    exprs
    |> Enum.flat_map(fn expr ->
      case expr do
        {operation, meta, [field, type]} ->
          opts = []
          [{operation, meta, [field, type, opts]}]
        {:timestamps, meta, []} ->
          opts = []
          [
            {:field, meta, [:inserted_at, :string, opts]},
            {:field, meta, [:updated_at, :string, opts]}
          ]
        _ ->
          [expr]
      end
    end)
    |> Enum.reduce([], fn {_operation, _, [field, _type, opts]}, acc ->
      required = Keyword.get(opts, :required, true)
      if required do
        acc ++ [field]
      else
        acc
      end
    end)
  end

end
