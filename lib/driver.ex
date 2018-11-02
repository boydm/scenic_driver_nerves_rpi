#
#  Created by Boyd Multerer on 02/14/18.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#
#  sends data to a glfw port app
#
defmodule Scenic.Driver.Nerves.Rpi do
  @moduledoc """
  # scenic_driver_nerves_rpi

  The main driver for rendering [Scenic](https://github.com/boydm/scenic) scenes on a Raspberry Pi device.

  So far only tested on Raspberry Pi 3 devices. In other words, it is still early
  days for this driver. There will probably be changes in the future. Especially
  regarding multi-touch.

  ## Installation

  In your Nerves applications dependencies include the following line

      ...
      {:scenic_driver_nerves_rpi, , "~> 0.9"}
      ...

  ## Configuration

  Configure the rpi driver the same way you configure other drivers. Add it
  to the driver list in your ViewPort's config.exs file.

      config :sample, :viewport, %{
            size: {800, 480},
            default_scene: {Sample.Scene.Simple, nil},
            drivers: [
              %{
                module: Scenic.Driver.Nerves.Rpi,
              }
            ]
          }


  ## Tips

  As I've used Scenic on a Raspberry Pi device, sometimes I want to make the whole
  Scene bigger in order to make it more readable. You can apply transforms to the
  entire ViewPort to achieve this. This looks the same as any list of styles or
  transforms that you would apply to any part of a graph.

  You can even rotate the entire scene if you want to change the orientation of
  the screen.

      config :sample, :viewport, %{
            size: {800, 480},
            opts: [scale: 1.2],    # <----- Apply transforms & styles here
            default_scene: {Sample.Scene.Simple, nil},
            drivers: [
              %{
                module: Scenic.Driver.Nerves.Rpi,
              }
            ]
          }

  ## Performance

  Performance on a Raspberry Pi is OK. Not Great. The VC4 chip is slower than I would
  like with 2D style drawing and there is an ongoing investigation to improve rendering performance.

  The good news is that Scenic only renders when there is a change. So if you aren't
  pushing graphs, then it isn't spending energy drawing the screen.
  """
  use Scenic.ViewPort.Driver
  alias Scenic.Cache

  alias Scenic.Driver.Nerves.Rpi

  require Logger

  # import IEx

  @port '/scenic_driver_nerves_rpi'

  # @default_width            -1      # -1 means to use the native width
  # @default_height           -1      # -1 means to use the native height

  @default_block_size 128

  @default_sync 15

  @default_debug false

  @default_clear_color {0, 0, 0, 0xFF}

  # ============================================================================
  # client callable api

  @doc """
  Retrieve stats about the driver
  """
  def query_stats(pid), do: GenServer.call(pid, :query_stats)

  # ============================================================================
  # startup
  @doc false
  def init(viewport, _, config) do
    # IO.puts "====================================================================="
    # IO.puts "====================================================================="
    # IO.puts "======================== Starting VC4 Driver ========================"
    # IO.puts "====================================================================="
    # IO.puts "====================================================================="

    # set up the port args - enforce type checking
    dl_block_size =
      cond do
        is_integer(config[:block_size]) -> config[:block_size]
        true -> @default_block_size
      end

    sync_interval =
      cond do
        is_integer(config[:sync]) -> config[:sync]
        true -> @default_sync
      end

    debug_mode =
      case config[:debug] do
        true -> 1
        false -> 0
        _ -> @default_debug
      end

    port_args = to_charlist(" #{dl_block_size} #{debug_mode}")

    # request put and delete notifications from the cache
    Cache.subscribe(:cache_put)
    Cache.subscribe(:cache_delete)

    # open and initialize the window
    Process.flag(:trap_exit, true)
    executable = :code.priv_dir(:scenic_driver_nerves_rpi) ++ @port ++ port_args

    # port = Port.open({:spawn, executable}, [:binary, {:packet, 4}])
    port = Port.open({:spawn, executable}, [:binary, {:packet, 4}])

    # IO.puts "------------------> executable: #{inspect(executable)}"
    # IO.puts "------------------> port: #{inspect(port)}"

    state = %{
      inputs: 0x0000,
      port: port,
      closing: false,
      ready: false,
      debounce: %{},
      root_ref: nil,
      dl_block_size: dl_block_size,
      start_dl: nil,
      end_dl: nil,
      last_used_dl: nil,
      dl_map: %{},
      used_dls: %{},
      clear_color: @default_clear_color,
      textures: %{},
      fonts: %{},
      dirty_graphs: [],
      sync_interval: sync_interval,
      draw_busy: false,
      pending_flush: false,
      currently_drawing: [],

      # window:         { width, height },
      screen_factor: 1.0,
      viewport: viewport
    }

    {:ok, state}
  end

  # ============================================================================
  # farm out handle_cast and handle_info to the supporting modules.
  # this module just got too long and complicated, so this cleans things up.

  # --------------------------------------------------------
  @doc false
  def handle_call(msg, from, state) do
    Rpi.Port.handle_call(msg, from, state)
    {:noreply, :e_no_impl, state}
  end

  # --------------------------------------------------------
  @doc false
  def handle_cast(msg, state) do
    msg
    |> do_handle(&Rpi.Graph.handle_cast(&1, state))
    |> do_handle(&Rpi.Cache.handle_cast(&1, state))
    |> do_handle(&Rpi.Port.handle_cast(&1, state))
    # |> do_handle( &Rpi.Font.handle_cast( &1, state ) )
    |> case do
      {:noreply, state} ->
        {:noreply, state}

      _ ->
        {:noreply, state}
    end
  end

  # --------------------------------------------------------
  def handle_info(:flush_dirty, %{ready: true} = state) do
    Rpi.Graph.handle_flush_dirty(state)
  end

  # --------------------------------------------------------
  def handle_info({:debounce, type}, %{ready: true} = state) do
    Rpi.Input.handle_debounce(type, state)
  end

  # --------------------------------------------------------
  def handle_info({msg_port, {:data, msg}}, %{port: port} = state) when msg_port == port do
    # def handle_info( {msg_port, {:data, msg }}, state ) do
    msg
    |> do_handle(&Rpi.Input.handle_port_message(&1, state))
  end

  # deal with the app exiting normally
  def handle_info({:EXIT, port_id, :normal} = msg, %{port: port, closing: closing} = state)
      when port_id == port do
    if closing do
      Logger.info("clean close")
      # we are closing cleanly, let it happen.
      GenServer.stop(self())
      {:noreply, state}
    else
      Logger.error("dirty close")
      # we are not closing cleanly. Let the supervisor recover.
      super(msg, state)
    end
  end

  # --------------------------------------------------------
  def handle_info(msg, state) do
    super(msg, state)
  end

  # --------------------------------------------------------
  defp do_handle({:noreply, _} = msg, _), do: msg

  defp do_handle(msg, handler) when is_function(handler) do
    handler.(msg)
  end
end
