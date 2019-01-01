defmodule SwaggerEcto.Helpers do
  @moduledoc """
  Helpers for defining schemas
  """

  def create_schema(source, exprs, env) do
    %PhoenixSwagger.Schema{
      title: title(source),
      properties: properties(exprs, env),
      required: required(exprs)
    }
  end

  def create_schema_list(source, exprs, env) do
    schema = create_schema(source, exprs, env)
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

  defp properties(exprs, env) do
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
      value = property(acc, expr, env)
      Map.merge(acc, value)
    end)
  end

  defp property(schema, {:field, _, [field, raw_type, _opts]}, env) do
    %{
      field => PhoenixSwagger.Schema.type(%PhoenixSwagger.Schema{}, type(raw_type))
    }
  end

  defp property(schema, {
    op,
    _,
    [
      field,
      {:__aliases__, _, [type]} = aliases,
      _opts
    ]
  } = ast, env) when op in [:has_one, :embeds_one, :belongs_to] do
    resolved_type =
        expand_alias(aliases, env)
        |> apply(:__swagger__, [:name])
        |> Inflex.singularize
        |> Macro.camelize()
        |> String.to_atom
    %{
      field => PhoenixSwagger.Schema.ref(resolved_type)
    }
  end

  defp property(schema, {
    op,
    _,
    [
      field,
      {:__aliases__, _, [type]} = aliases,
      _opts
    ]
  }, env) when op in [:has_many, :embeds_many] do
    plural_field = Inflex.pluralize(field) |> String.to_atom
    resolved_type =
        expand_alias(aliases, env)
        |> apply(:__swagger__, [:name])
        |> Inflex.pluralize
        |> Macro.camelize()
        |> String.to_atom
    %{
      plural_field => PhoenixSwagger.Schema.ref(resolved_type)
    }
  end

  defp property(schema, {:timestamps, _, []}, env) do
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

  defp expand_alias({:__aliases__, _, _} = ast, env),
    do: Macro.expand(ast, env)
  defp expand_alias(ast, _env),
    do: ast

end
