defmodule SwaggerEcto.SchemaTest do
  use ExUnit.Case

  defmodule TestSchema do
    use SwaggerEcto.Schema

    swagger_schema "people" do
      field :name, :string
      field :country, :string
      field :age, :integer, required: false
    end

  end

  test "it defines a swagger schema" do
    assert TestSchema.__schema__(:swagger) == %{
      "title" => "Person",
      "required" => [
        "id",
        "name",
        "country"
      ],
      "properties" => %{
        "id" => %{
          "type" => "integer"
        },
        "name" => %{
          "type" => "string"
        },
        "country" => %{
          "type" => "string"
        },
        "age" => %{
          "type" => "integer"
        }
      }
    }
  end

  defmodule TestSchemaWithBinaryId do
    use SwaggerEcto.Schema

    @primary_key {:uuid, :binary_id, []}
    swagger_schema "people" do
      field :name, :string
    end

  end

  test "it works with custom ID directive" do
    assert TestSchemaWithBinaryId.__schema__(:swagger) == %{
      "title" => "Person",
      "required" => [
        "uuid",
        "name"
      ],
      "properties" => %{
        "uuid" => %{
          "type" => "string"
        },
        "name" => %{
          "type" => "string"
        }
      }
    }
  end

end
