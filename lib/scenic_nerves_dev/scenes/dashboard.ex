defmodule ScenicNervesDev.Scene.Dashboard do
  use Scenic.Scene

  alias Scenic.Graph
  alias Scenic.Primitive
  alias Scenic.Component
  import Scenic.Primitives

  # import IEx

  @pi               :math.pi()
  @min_ms           100
  @max_ms           2000
  @start_ms         200
  @spread_ms        @max_ms - @min_ms

  #============================================================================
  # setup

  #--------------------------------------------------------
  def init( _, _ ) do
    graph = Graph.build( font: :roboto, font_size: 20 )
    |> text("scenic_nerves_dev", translate: {20, 40} )
    |> text("This Scenic UI is being projected from a RPI device running Nerves",
      translate: {20, 100} )

    |> text(to_string(@start_ms * 2), font_size: 140, translate: {20, 300}, id: :speed)

    # numeric slider
    |> Component.Input.Slider.add_to_graph( {{@min_ms,@max_ms}, @start_ms, 300, :speed_slider},
      id: :num_slider, translate: {20,400} )

    # angle output
    |> group(fn(graph) ->
      graph

      # add the outline
      |> sector( {0, @pi, 100}, color: :clear, border_width: 10, border_color: :white )

      # add the current speed sector
      |> sector( {0, 0, 100}, color: :green, id: :speedometer )

    end, rotate: @pi, translate: {500,300})
    |> push_graph()

    {:ok, graph}
  end

  #============================================================================
  # event filters

  #--------------------------------------------------------
  def filter_event( {:value_changed, :speed_slider, value}, _, graph ) do

    graph = graph
    |> Graph.modify(:speed, fn(p) ->
      Primitive.put( p, to_string(value * 2) )
    end)
    |> Graph.modify(:speedometer, fn(p) ->
      Primitive.put( p, {{0,0}, 0, ((value - @min_ms) / @spread_ms) * @pi, 100, {1,1}} )
    end)
    |> push_graph()

    # send the new value to the blinky service
    GenServer.cast(:blinky, {:set_half_period, value})

    {:stop, graph }
  end

end