defmodule Scenic.Driver.Nerves.Rpi.MixProject do
  use Mix.Project

  def project do
    [
      app: :scenic_driver_nerves_rpi,
      version: "0.7.0",
      package: package(),
      elixir: "~> 1.6",
      description: description(),
      start_permanent: Mix.env() == :prod,
      compilers: [:elixir_make] ++ Mix.compilers,
      make_clean: ["clean"],
      make_targets: ["all"],
      make_env: make_env(),
      deps: deps()
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
      { :elixir_make, "~> 0.4" },
      { :scenic, git: "~> 0.7" }
    ]
  end

  defp description() do
    """
    Scenic.Driver.Nerves.Rpi - Scenic driver providing drawing (only) on a Raspberry Pi under Nerves.
    """
  end

  defp package() do
    [
      name: :scenic_driver_nerves_rpi,
      maintainers: ["Boyd Multerer"]
    ]
  end

  defp make_env() do
    case System.get_env("ERL_EI_INCLUDE_DIR") do
      nil ->
        %{
          "ERL_EI_INCLUDE_DIR" => "#{:code.root_dir()}/usr/include",
          "ERL_EI_LIBDIR" => "#{:code.root_dir()}/usr/lib",
        }

      _ ->
        %{}
    end
  end

end
