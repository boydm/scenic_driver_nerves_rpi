# # scenic_driver_nerves_rpi

The main driver for rendering [Scenic](https://github.com/boydm/scenic) scenes on a Raspberry Pi device.

So far only tested on Raspberry Pi 3 devices. In other words, it is still early
days for this driver. There will probably be changes in the future. Especially
regarding multi-touch.

## Installation

In your Nerves applications dependencies include the following line

    ...
    {:scenic_driver_nerves_rpi, , "~> 0.10"}
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
