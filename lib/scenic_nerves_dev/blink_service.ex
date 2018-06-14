defmodule ScenicNervesDev.BlinkyService do
  use GenServer
  alias Nerves.Leds

  # import IEx

  #--------------------------------------------------------
  def start_link( half_period ) do
    GenServer.start_link(__MODULE__, half_period, name: :blinky)
  end

  #--------------------------------------------------------
  def init( half_period ) do
    # IO.puts "======================================================================"
    # IO.puts "======================================================================"
    # IO.puts "======================================================================"
    # IO.puts "======================= Starting BlinkyService ======================="
    # IO.puts "======================= #{inspect(half_period)} ======================="
    # IO.puts "======================================================================"
    # IO.puts "======================================================================"
    # IO.puts "======================================================================"

    {:ok, timer} = :timer.send_interval(half_period, :blink)

    state = %{
      half_period: half_period,
      led_state: true,
      led_list: Application.get_env(:scenic_nerves_dev, :led_list),
      timer: timer
    }

    # start the timer and return
    {:ok, state }
  end

  #--------------------------------------------------------
  def handle_cast({:set_half_period, half_period}, %{
    timer: timer
  } = state) do
    if timer, do: :timer.cancel(timer)
    {:ok, timer} = :timer.send_interval(half_period, :blink)
    {:noreply, %{state | half_period: half_period, timer: timer} }
  end

  #--------------------------------------------------------
  def handle_info(:blink, %{
    half_period: half_period,
    led_state: led_state,
    led_list: led_list
  } = state) do
    # negate the state
    led_state = !state.led_state
    
    # blink
    Enum.each(led_list, &Leds.set([{&1, led_state}]) )

    {:noreply, %{state | led_state: led_state} }
  end

end