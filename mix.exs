defmodule SwaggerEcto.MixProject do
  use Mix.Project

  def project do
    [
      app: :swagger_ecto,
      version: "0.2.9",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix_swagger, "~> 0.8.1"},
      {:inflex, "~> 1.10.0"},
      {:ecto, "~> 2.1.6"},
      {:mix_test_watch, "~> 0.8", only: :dev, runtime: false},
      {:credo, "~> 1.0.0", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.14", only: :dev}
    ]
  end

  defp description do
    "Extends Ecto schemas with Swagger definitons"
  end

  defp package do
    [
      # This option is only needed when you don't want to use the OTP application name
      name: "swagger_ecto",
      # These are the default files included in the package
      files: ~w(lib .formatter.exs mix.exs),
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/madshargreave/swagger_ecto"}
    ]
  end

end
