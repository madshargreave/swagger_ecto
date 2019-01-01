defmodule SwaggerEcto.SchemaTest do
  use ExUnit.Case

  defmodule PersonSchema do
    use SwaggerEcto.Schema
    swagger_schema "people" do
      field :name, :string
      field :country, :string
      field :age, :integer, required: false
    end
  end

  defmodule CountrySchema do
    use SwaggerEcto.Schema
    swagger_schema "countries" do
      field :name, :string
    end
  end

  test "it defines a swagger schema" do
    assert PersonSchema.__swagger__() == %{
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

  test "it works with lists" do
    assert PersonSchema.__swagger__(:list) == %{
      "title" => "People",
      "type" => "array",
      "items" => %{
        "$ref" => "#/definitions/Person"
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
    assert TestSchemaWithBinaryId.__swagger__() == %{
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

  defmodule TestSchemaWithAssoc do
    use SwaggerEcto.Schema
    alias SwaggerEcto.SchemaTest.PersonSchema

    swagger_schema "people" do
      has_one :parent, PersonSchema
    end

  end

  test "it works with assocs" do
    assert TestSchemaWithAssoc.__swagger__() == %{
      "title" => "Person",
      "required" => [
        "id",
        "parent"
      ],
      "properties" => %{
        "id" => %{
          "type" => "integer"
        },
        "parent" => %{
          "$ref" => "#/definitions/Person"
        }
      }
    }
  end

  defmodule TestSchemaWithOneToManyAssoc do
    use SwaggerEcto.Schema

    swagger_schema "people" do
      has_many :countries, CountrySchema
      embeds_many :other_countries, CountrySchema
    end

  end

  test "it works with one-to-many assocs" do
    assert TestSchemaWithOneToManyAssoc.__swagger__() == %{
      "title" => "Person",
      "required" => [
        "id",
        "countries",
        "other_countries"
      ],
      "properties" => %{
        "id" => %{
          "type" => "integer"
        },
        "countries" => %{
          "$ref" => "#/definitions/Countries"
        },
        "other_countries" => %{
          "$ref" => "#/definitions/Countries"
        }
      }
    }
  end

  defmodule TestSchemaWithEmbed do
    use SwaggerEcto.Schema

    swagger_schema "people" do
      embeds_one :country, CountrySchema
    end

  end

  test "it works with embeds" do
    assert TestSchemaWithEmbed.__swagger__() == %{
      "title" => "Person",
      "required" => [
        "id",
        "country"
      ],
      "properties" => %{
        "id" => %{
          "type" => "integer"
        },
        "country" => %{
          "$ref" => "#/definitions/Country"
        }
      }
    }
  end

  defmodule TestSchemaWithTimestamps do
    use SwaggerEcto.Schema

    swagger_schema "people" do
      timestamps()
    end

  end

  test "it works with timestamps macro" do
    assert TestSchemaWithTimestamps.__swagger__() == %{
      "title" => "Person",
      "required" => [
        "id",
        "inserted_at",
        "updated_at"
      ],
      "properties" => %{
        "id" => %{
          "type" => "integer"
        },
        "inserted_at" => %{
          "type" => "string"
        },
        "updated_at" => %{
          "type" => "string"
        }
      }
    }
  end

  defmodule EmbeddedSchema do
    use SwaggerEcto.Schema
    swagger_embedded_schema "countries" do
      field :name, :string
    end
  end

  test "it works with embedded ecto schemas" do
    assert EmbeddedSchema.__swagger__() == %{
      "title" => "Country",
      "required" => [
        "name"
      ],
      "properties" => %{
        "name" => %{
          "type" => "string"
        }
      }
    }
  end

  test "it works with embedded lists" do
    assert EmbeddedSchema.__swagger__(:list) == %{
      "title" => "Countries",
      "type" => "array",
      "items" => %{
        "$ref" => "#/definitions/Country"
      }
    }
  end

end
