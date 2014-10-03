require 'BlinkyTape'
require 'color'

class Blinkz
  extend Color
  def initialize
    @blinky = BlinkyTape.new('/dev/tty.usbmodem1421')
  end

  def change_one_color index, rgb_options
    0..(index-1).times do |idx|
      @blinky.send_pixel 0,0,0
    end

    @blinky.send_pixel(rgb_options[:r], rgb_options[:g], rgb_options[:b])
    refresh
  end

    def gradient color
      0..60.times do |idx|
        new_color = color.darken_by idx*3.25
        @blinky.send_pixel new_color.red.to_i, new_color.green.to_i, new_color.blue.to_i
      end
      refresh
    end

    def gradient_one index, color
      0..100.times do |idx|
        0..(index-2).times do
          @blinky.send_pixel 0,0,0
        end

        new_color = color.darken_by idx
        @blinky.send_pixel new_color.red.to_i, new_color.green.to_i, new_color.blue.to_i

        new_color = color.lighten_by idx
        @blinky.send_pixel new_color.red.to_i, new_color.green.to_i, new_color.blue.to_i

        index..60.times do
          @blinky.send_pixel 0,0,0
        end
        refresh
      end
    end

    def animate_color start_color, end_color, iterations = 100
      0..iterations.times do |idx|
        new_color = end_color.mix_with(start_color, 100*(idx.to_f / iterations))
        60.times { @blinky.send_pixel new_color.red.to_i, new_color.green.to_i, new_color.blue.to_i }
        refresh
      end
      self
    end

    def animate_colors iterations, *args
      last_color = nil
      args.each do |color|
        rgb_color = Object.const_get("Color::RGB::#{color.capitalize}")
        unless last_color.nil?
          animate_color last_color, rgb_color, iterations
        end
        last_color = rgb_color
      end
    end

    def refresh
      @blinky.show
      @blinky.show
      @blinky.show
    end
end

def setup
  @b.connect
end

