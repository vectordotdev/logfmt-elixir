defmodule Logfmt.Mixfile do
  use Mix.Project

  @version "1.0.3"

  def project do
    [app: :timber_logfmt,
     version: @version,
     elixir: ">= 1.2.0",
     deps: deps(),
     package: package(),
     description: "A simple logfmt decoder",
     name: "Logfmt",
     docs: [extras: ["README.md"], main: "readme",
            source_ref: "v#{@version}",
            source_url: "https://github.com/timberio/logfmt-elixir"]]
  end

  # Configuration for the OTP application
  def application do
    [applications: []]
  end

  def deps do
    [{:ex_doc, ">= 0.0.0", only: :dev}]
  end

  defp package do
    %{licenses: ["Unlicense"],
      maintainers: ["Timber.io development team"],
      links: %{"GitHub" => "https://github.com/timberio/logfmt-elixir",
               "Timber" => "https://timber.io"}}
  end
end