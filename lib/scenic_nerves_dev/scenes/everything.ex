defmodule ScenicNervesDev.Scene.Everything do
  use Scenic.Scene

  alias Scenic.Graph
  alias Scenic.Primitive
  alias Scenic.Component
  import Scenic.Primitives

  import IEx

  @lola_jpg                 "/static/textures/lola.jpg.gwAj0XwB3g-FvrcDb949qfcU3_k"
  @lola_hash                "gwAj0XwB3g-FvrcDb949qfcU3_k"

  @graph Graph.build( font: :roboto, font_size: 20 )
    |> line( {{340,20}, {400,80}}, stroke: {4, :red} )
    |> line( {{400,20}, {460,80}}, stroke: {20, :green}, cap: :butt )
    |> line( {{460,20}, {520,80}}, stroke: {20, :yellow}, cap: :round )
    |> line( {{520,20}, {580,80}}, stroke: {20, :blue}, cap: :square )

    |> line( {{0,0}, {60,70}}, stroke: {4, :red}, translate: {340,110} )
    |> line( {{0,0}, {60,70}},
      stroke: {20, {:linear, {0,0,60,70,:yellow,:purple}}},
      cap: :butt, translate: {400,110}
    )
    |> line( {{0,0}, {60,70}},
      stroke: {20, {:box, {0,0,60,70, 20, 20, :yellow, :purple }}},
      cap: :round, translate: {460,110}
    )
    |> line( {{0,0}, {60,70}},
      stroke: {20, {:radial, {30,35, 10,30, :yellow, :purple }}},
      cap: :square, translate: {520,110}
    )

    |> triangle( {{20, 200}, {300, 200}, {300, 0}},
    id: :tri, fill: :cornflower_blue, stroke: {10, :green} )
    |> circle( {{100, 80}, 60}, fill: {:green, 128}, stroke: {6, :yellow})
    |> ellipse( {{200, 100}, 60, 90}, rotate: 0.5, fill: :green, stroke: {4, :gray})


    |> rect({160,100}, id: :rect, translate: {10,220},
      stroke: {12, :slate_blue},
      fill: :dark_turquoise
    )
    |> rect({160,100}, id: :rect, translate: {210,220}, join: :round,
      stroke: {12, :slate_blue},
      fill: {:linear, {0,0,160,100,:yellow,:purple}}
    )
    |> rect({160,100}, id: :rect, translate: {410,220}, join: :miter,
      stroke: {12, :slate_blue},
      fill: {:box, {0,0,160,100, 100,20, :yellow, :purple }}
    )
    |> rect({160,100}, id: :rect, translate: {610,220}, join: :bevel,
      stroke: {12, :slate_blue},
      fill: {:radial, {80,50, 20,60, {:yellow, 128}, {:purple, 128} }}
    )

    |> rrect({160,100,30}, id: :rect, translate: {10,340},
      stroke: {12, :slate_blue},
      fill: :dark_turquoise
    )
    |> quad( {{200,360},{300,370},{340,450},{300,460}}, id: :quad,
      stroke: {10, :yellow},
      fill: :red,
      miter_limit: 2
    )
    |> sector( {160, -0.3, -0.8},
      stroke: {3, :grey},
      fill: {:radial, {0,0, 20,160, {:yellow, 128}, {:purple, 128} }},
      translate: {360,460}
    )
    |> arc( {80, -0.3, 1.8},
      stroke: {8, :cornflower_blue},
      translate: {500,380}
    )

    |> text("Hello", translate: {20, 490}, font_size: 40)
    |> text("World", translate: {106, 490}, font: :roboto, font_size: 40, fill: :yellow)

    |> text("Left\nJustified", translate: {20, 520})
    |> text("Right\nJustified", translate: {180, 520}, text_align: :right)
    |> text("Center\nJustified", translate: {50, 560}, text_align: :center)
    |> text("Blur", translate: {120, 580}, font: :roboto, font_size: 40, font_blur: 2)

    |> rect({400, 400}, id: :rect,
      fill: {:image, @lola_hash},
      stroke: {6, :lavender},
      pin: {0,0}, translate: {240, 480}#, scale: 0.3
    )

    |> group(fn(graph) ->
      graph
      |> Component.Button.add_to_graph( {"Button", :button})
      |> Component.Input.Checkbox.add_to_graph({"Checkbox", :checkbox, true}, translate: {0,60})
      |> Component.Input.RadioGroup.add_to_graph({[
          {"Radio A", :radio_a, false},
          {"Radio B", :radio_b, true}
        ], :radio_group }, translate: {0,90} )
      |> Component.Input.Slider.add_to_graph( {{0,100}, 20, 300, :slider}, translate: {0,130} )
    end, translate: {660,400})


  #============================================================================
  # setup

  #--------------------------------------------------------
  def init( _, _ ) do
    push_graph(@graph)
    {:ok, @graph}
  end

  #============================================================================
  def handle_set_root( _vp, _args, graph ) do

    # load the dog texture into the cache
    :code.priv_dir(:scenic_nerves_dev)
    |> Path.join( @lola_jpg )
    |> Scenic.Cache.Texture.load()

    {:noreply, graph }
  end

end