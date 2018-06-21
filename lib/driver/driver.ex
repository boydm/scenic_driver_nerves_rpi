#
#  Created by Boyd Multerer on 02/14/18.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#
#  sends data to a glfw port app
#
defmodule Scenic.Driver.Rpi do
  use Scenic.ViewPort.Driver
  alias Scenic.Cache

  alias Scenic.Driver.Rpi

  require Logger

  import IEx

  @port  '/scenic_driver_rpi'

  @default_width            -1      # -1 means to use the native width
  @default_height           -1      # -1 means to use the native height

  @default_block_size       128

  @default_sync             15

  @default_debug            false

  #============================================================================
  # client callable api

  def query_stats( pid ),               do: GenServer.call( pid, :query_stats )

  #============================================================================
  # startup

  def init( viewport, config ) do

    # IO.puts "====================================================================="
    # IO.puts "====================================================================="
    # IO.puts "======================== Starting VC4 Driver ========================"
    # IO.puts "====================================================================="
    # IO.puts "====================================================================="

    # set up the port args - enforce type checking
    dl_block_size = cond do
      is_integer(config[:block_size]) -> config[:block_size ]
      true                        -> @default_block_size
    end
    sync_interval = cond do
      is_integer(config[:sync])   -> config[:sync]
      true                        -> @default_sync
    end

    debug_mode = case config[:debug] do
      true    -> 1
      false   -> 0
      _       -> @default_debug
    end

    port_args = to_charlist(" #{dl_block_size} #{debug_mode}")

    # request put and delete notifications from the cache
    Cache.request_notification( :cache_put )
    Cache.request_notification( :cache_delete )

    # open and initialize the window
    Process.flag(:trap_exit, true)
    executable = :code.priv_dir(:scenic_driver_rpi) ++ @port ++ port_args

    # port = Port.open({:spawn, executable}, [:binary, {:packet, 4}])
    port = Port.open({:spawn, executable}, [:binary, {:packet, 4}])

    # IO.puts "------------------> executable: #{inspect(executable)}"
    # IO.puts "------------------> port: #{inspect(port)}"

    state = %{
      inputs:         0x0000,
      port:           port,
      closing:        false,
      ready:          false,
      debounce:       %{},

      root_ref:       nil,
      dl_block_size:  dl_block_size,
      start_dl:       nil,
      end_dl:         nil,
      last_used_dl:   nil,
      dl_map:         %{},
      used_dls:       %{},

      textures:       %{},
      fonts:          %{},

      dirty_graphs:   [],
      sync_interval:  sync_interval,
      draw_busy:      false,
      pending_flush:  false,
      currently_drawing: [],

      # window:         { width, height },
      screen_factor:  1.0,

      viewport:       viewport
    }

    {:ok, state }
  end

  #============================================================================
  # farm out handle_cast and handle_info to the supporting modules.
  # this module just got too long and complicated, so this cleans things up.

  #--------------------------------------------------------
  def handle_call( msg, from, state ) do
    Rpi.Port.handle_call(msg, from, state )
    {:noreply, :e_no_impl, state}
  end

  #--------------------------------------------------------
  def handle_cast( msg,  state ) do #%{ready: true} =
    msg
    |> do_handle( &Rpi.Graph.handle_cast( &1, state ) )
    |> do_handle( &Rpi.Cache.handle_cast( &1, state ) )
    |> do_handle( &Rpi.Port.handle_cast( &1, state ) )
    # |> do_handle( &Rpi.Font.handle_cast( &1, state ) )
    |> case do
      {:noreply, state} ->
        {:noreply, state}
      _ ->
        {:noreply, state}
    end
  end

  #--------------------------------------------------------
  def handle_info( :flush_dirty, %{ready: true} = state ) do
    Rpi.Graph.handle_flush_dirty( state )
  end

  #--------------------------------------------------------
  def handle_info( {:debounce, type}, %{ready: true} = state ) do
    Rpi.Input.handle_debounce( type, state )
  end

  #--------------------------------------------------------
  def handle_info( {msg_port, {:data, msg }}, %{port: port} = state ) when msg_port == port do
  # def handle_info( {msg_port, {:data, msg }}, state ) do
    msg
    |> do_handle( &Rpi.Input.handle_port_message(&1, state) )
  end

  # deal with the app exiting normally
  def handle_info( {:EXIT, port_id, :normal} = msg, %{port: port, closing: closing} = state ) when port_id == port do
    if closing do
      Logger.info( "clean close" )
      # we are closing cleanly, let it happen.
      GenServer.stop( self() )
      {:noreply, state}
    else
      Logger.error( "dirty close" )
      # we are not closing cleanly. Let the supervisor recover.
      super(msg, state)
    end
  end

  #--------------------------------------------------------
  def handle_info( msg, state ) do
    super(msg, state)
  end


  #--------------------------------------------------------
  defp do_handle( {:noreply, _} = msg, _ ), do: msg
  defp do_handle( msg, handler ) when is_function(handler) do
    handler.(msg)
  end

end