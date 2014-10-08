require 'BlinkyTape'
require 'color'
require 'ostruct'

class ColorHelper
  def self.random_hex_color
    Color::RGB.from_html ("%06x" % (rand * 0xffffff))
  end
end

class RGBLight
  extend Color
  attr_accessor :iterations

  def initialize start_color: Color::RGB::Blue, end_color: Color::RGB::Red, iterations: 10, animation: :fade
    @start_color = start_color
    @end_color = end_color
    @iterations = iterations
    @animation = animation
  end

  def r idx
    calc :red, idx
  end

  def g idx
    calc :green, idx
  end

  def b idx
    calc :blue, idx
  end

  private

  def calc color, idx
    if @animation == :fade
      @end_color.mix_with(@start_color, 100 * (idx.to_f / @iterations)).send(color.to_s).to_i
    elsif @animiation == :ligten
      @end_color.lighten_by(100 * (idx.to_f / @iterations)).send(color.to_s).to_i
    elsif @animation == :darken
      @end_color.darken_by(100 * (idx.to_f / @iterations)).send(color.to_s).to_i
    end
  end
end

class ColorSet
  attr_accessor :colors_array, :total_iterations
  def initialize colors
    @colors_array = []
    @total_iterations = 0
    colors.each do |rgb|
      @total_iterations += rgb.iterations
      rgb.iterations.times do |idx|
        @colors_array << OpenStruct.new(r: rgb.r(idx), g: rgb.g(idx), b: rgb.b(idx))
      end
    end
  end
end

class BlinkyController
  def initialize
    @lights = []
    @strip = BlinkyStrip.new
  end

  def full_fade iterations
    @color_sets = []
    60.times { @color_sets << ColorSet.new([RGBLight.new(iterations: iterations)]) }
    @strip.send_colors @color_sets
    self
  end

  def random_fade iterations
    @color_sets = []
    60.times { @color_sets << ColorSet.new([RGBLight.new(iterations: iterations, start_color: ColorHelper.random_hex_color, end_color: ColorHelper.random_hex_color)]) }
    @strip.send_colors @color_sets
    self
  end

  def long_random iterations
    @color_sets = []
    60.times do |idx|
      colors = []
      50.times do
        @start_color = @end_color || ColorHelper.random_hex_color
        @end_color = ColorHelper.random_hex_color
        colors << RGBLight.new(iterations: (iterations).to_i, start_color: @start_color, end_color: @end_color) 
      end
      @color_sets[idx] = ColorSet.new colors
    end
    @strip.send_colors @color_sets
    self
  end
end

class BlinkyStrip
  extend Color
  def initialize
    @blinky = BlinkyTape.new('/dev/tty.usbmodem1421')
  end

  def send_color color
    @blinky.send_pixel color.r, color.g, color.b
  end

  def send_colors color_set
    color_set.map(&:total_iterations).max.times do |idx|
      60.times do |light|
        send_color(color_set[light].colors_array[idx])
      end
      show
    end
  end

  def show
    @blinky.show
    @blinky.show
    @blinky.show
  end
end

