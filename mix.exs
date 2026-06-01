defmodule ConvertToHex.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :convert_to_hex,
      version: @version,
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_options: [warnings_as_errors: true]
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:image, "~> 0.54"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end
end
