defmodule ScenicNervesDev.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  @target Mix.Project.config()[:target]

  use Application

  def start(_type, _args) do
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ScenicNervesDev.Supervisor]
    Supervisor.start_link(children(@target), opts)
  end

  # List all child processes to be supervised
  def children("host") do
    [
      # Starts a worker by calling: ScenicNervesDev.Worker.start_link(arg)
      # {ScenicNervesDev.Worker, arg},
    ]
  end

  def children(_target) do
    import Supervisor.Spec, warn: false

    # set up the default viewport configuration
    # set up the default viewport configuration
    # This could easily be in a config file.
    main_viewport_config = %Scenic.ViewPort.Config{
      name: :main_viewport,
      default_scene: {ScenicNervesDev.Scene.Everything, nil},
      drivers: [
        %Scenic.ViewPort.Driver.Config{
          module: Scenic.Driver.Rpi,
          name: :rpi_driver,
          opts: [debug: false],
        },
        # %Scenic.ViewPort.Driver.Config{
        #   name: :remote,
        #   module: Scenic.Remote.Driver,
        #   opts: [socket: :rpi_socket]
        # },
      ]
    }

    [
      # Starts a worker by calling: ScenicNervesOne.Worker.start_link(arg)
      {ScenicNervesDev.BlinkyService, 200},
      # supervisor(K10.Socket, [[:rpi_socket]]),
      supervisor(Scenic.Supervisor, [viewports: [main_viewport_config]]),
    ]
  end
end
