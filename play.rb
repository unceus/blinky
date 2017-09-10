require 'BlinkyTape'
require 'color'
require 'ostruct'
require 'pry'

class ColorHelper
  def self.random_hex_color
    Color::RGB.from_html ("%06x" % (rand * 0xffffff))
  end

  def self.ensure_nonzero num
    if num.zero?
      1
    else
      num
    end
  end
end

class RGBLight
  extend Color
  attr_accessor :iterations

  def initialize start_color: Color::RGB::Blue, end_color: Color::RGB::Blue, iterations: 10, animation: :fade
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

  def start_color
    @start_color
  end

  def end_color
    @end_color
  end

  def iterations
    @iterations
  end

  def rgb_colors_array
    arr = []
    iterations.times do |idx|
      arr << OpenStruct.new(r: r(idx), g: g(idx), b: b(idx))
    end
    arr
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

class BlinkyController
  def initialize
    @lights = []
    @strip = BlinkyStrip.new
  end

  def full_fade iterations
    @strip.send_colors RGBLight.new(iterations: iterations, end_color: Color::RGB::Red).rgb_colors_array
    self
  end

  def random_fade iterations, fade_length
    @color_sets = []
    @raw_colors = []

    (iterations+1).times { @raw_colors << ColorHelper.random_hex_color }

    60.times do |light_idx|
      @colors = []

      iterations.times do |color_idx|
        @colors << RGBLight.new(iterations: fade_length, start_color: @raw_colors[color_idx], end_color: @raw_colors[color_idx+1])
      end

      @color_sets[light_idx] = ColorSet.new(@colors)
    end

    @strip.send_colors @color_sets
    self
  end

  def fade_duration duration_seconds, iterations_seed = 50
    colors = RGBLight.new(iterations: ColorHelper.ensure_nonzero(rand(iterations_seed)), start_color: ColorHelper.random_hex_color, end_color: ColorHelper.random_hex_color)
    current_time = frames = current_frame = 0
    start = Time.now

    while Time.now - start < duration_seconds
      if frames == 0 || frames < current_frame
        colors = RGBLight.new(iterations: ColorHelper.ensure_nonzero(rand(iterations_seed)), start_color: colors.end_color, end_color: ColorHelper.random_hex_color)
        frames = colors.iterations - 1
        current_frame = 0
      end
      @strip.send_colors [colors.rgb_colors_array[current_frame]]
      current_frame = current_frame + 1
    end
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
    @blinky = BlinkyTape.new('/dev/cu.usbmodemFA131')
  end

  def send_color color
    @blinky.send_pixel color.r, color.g, color.b
  end

  def send_colors color_set
    color_set.each do |color|
      60.times do |light|
        send_color(color)
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

