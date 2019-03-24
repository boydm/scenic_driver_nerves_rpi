defmodule Scenic.Driver.Nerves.Rpi.MixProject do
  use Mix.Project

  # note to self: to publish set PUBLISH=1 on command line

  @app_name :scenic_driver_nerves_rpi
  @version "0.10.0"
  @github "https://github.com/boydm/scenic_driver_nerves_rpi"

  def project do
    [
      app: @app_name,
      version: @version,
      elixir: "~> 1.6",
      description: description(),
      build_embedded: true,
      start_permanent: Mix.env() == :prod,
      compilers: compilers(),
      make_clean: ["clean"],
      make_targets: ["all"],
      make_env: make_env(),
      deps: deps(),
      package: package(),
      docs: [extras: ["README.md"]]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: []
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:scenic, "~> 0.9"},
      {:elixir_make, "~> 0.4", runtime: false},
      {:ex_doc, "~> 0.19", only: [:dev, :test], runtime: false}
    ]
  end

  defp description() do
    """
    Scenic.Driver.Nerves.Rpi - Scenic driver providing drawing (only) on a Raspberry Pi under Nerves.
    """
  end

  defp make_env() do
    case System.get_env("ERL_EI_INCLUDE_DIR") do
      nil ->
        %{
          "ERL_EI_INCLUDE_DIR" => "#{:code.root_dir()}/usr/include",
          "ERL_EI_LIBDIR" => "#{:code.root_dir()}/usr/lib"
        }

      _ ->
        %{}
    end
  end

  defp compilers() do
    compilers(System.get_env("PUBLISH"))
  end

  defp compilers(nil) do
    [:elixir_make] ++ Mix.compilers()
  end

  defp compilers(_publish) do
    Mix.compilers()
  end

  defp package do
    [
      name: @app_name,
      contributors: ["Boyd Multerer"],
      maintainers: ["Boyd Multerer"],
      licenses: ["Apache 2"],
      links: %{Github: @github},
      files: [
        "Makefile",
        "LICENSE",
        # only include *.c and *.h files
        "c_src/**/*.[ch]",
        # only include *.ex files
        "lib/**/*.ex",
        "mix.exs",
        "priv/*"
      ]
    ]
  end
end
