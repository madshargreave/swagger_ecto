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
    |> Enum.reduce(%{}, fn expr, acc ->
      value = property(expr)
      Map.merge(acc, value)
    end)
  end

  defp property({:field, _, [field, type, _opts]}) do
    %{
      field => %{
        type: type
      }
    }
  end

  defp required(exprs) do
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
