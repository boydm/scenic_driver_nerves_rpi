defmodule ScenicNervesDev.Scene.Simple do
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


  @graph Graph.build(  )
    |> line( {{0,0}, {800,800}}, stroke: {4, :red} )
    |> line( {{800,0}, {0,800}}, stroke: {8, :yellow} )

    |> triangle( {{20, 300}, {400, 300}, {400, 0}},
    id: :tri, fill: :cornflower_blue, stroke: {10, :green} )
    |> circle( {{100, 80}, 60}, fill: {:green, 128}, stroke: {6, :yellow})
    |> ellipse( {{100, 100}, 60, 90}, rotate: 0.5, fill: :green, stroke: {4, :gray})

  #============================================================================
  # setup

  #--------------------------------------------------------
  def init( _, _ ) do
    push_graph(@graph)
    {:ok, @graph}
  end

  #============================================================================
  # event filters

end