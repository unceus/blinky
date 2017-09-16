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

  def rgb(idx)
    OpenStruct.new(r: r(idx), g: g(idx), b: b(idx))
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
    @strip.send_color RGBLight.new(iterations: iterations, end_color: Color::RGB::Red).rgb_colors_array
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

    @strip.send_color @color_sets
    self
  end

  def fade_duration duration_seconds = 60, iterations_seed = 50
    colors = RGBLight.new(iterations: ColorHelper.ensure_nonzero(rand(iterations_seed)), start_color: ColorHelper.random_hex_color, end_color: ColorHelper.random_hex_color)
    current_time = frames = current_frame = 0
    start = Time.now

    while Time.now - start < duration_seconds
      if frames == 0 || frames < current_frame
        colors = RGBLight.new(iterations: ColorHelper.ensure_nonzero(rand(iterations_seed)), start_color: colors.end_color, end_color: ColorHelper.random_hex_color)
        frames = colors.iterations - 1
        current_frame = 0
      end
      @strip.send_color [colors.rgb_colors_array[current_frame]]
      current_frame = current_frame + 1
    end
  end

  def fade_cascade(duration_seconds: 60, iterations: 50, colors: :random)
    frames = []
    start = Time.now

    if colors == :random
      current_color = RGBLight.new(iterations: ColorHelper.ensure_nonzero(rand(iterations)), start_color: ColorHelper.random_hex_color, end_color: ColorHelper.random_hex_color)
    else
      first_color, color_idx = get_next_color(colors, colors.length)
      next_color, color_idx = get_next_color(colors, color_idx)
      current_color = RGBLight.new(iterations: iterations, start_color: first_color, end_color: next_color)
    end

    frames = frames + current_color.rgb_colors_array

    while frames.length < 60
      if colors == :random
        next_color = ColorHelper.random_hex_color
      else
        next_color, color_idx = get_next_color(colors, color_idx)
      end

      current_color = RGBLight.new(iterations: colors == :random ? ColorHelper.ensure_nonzero(rand(iterations)) : iterations, start_color: current_color.end_color, end_color: next_color)
      frames = frames + current_color.rgb_colors_array
    end

    while Time.now - start < duration_seconds

      @strip.send_colors(frames.slice(0, 60))
      frames = frames.slice(1, frames.length)

      if frames.length < 60
        if colors == :random
          current_color = RGBLight.new(iterations: ColorHelper.ensure_nonzero(rand(iterations)), start_color: current_color.end_color, end_color: ColorHelper.random_hex_color)
        else
          next_color, color_idx = get_next_color(colors, color_idx)
          current_color = RGBLight.new(iterations: ColorHelper.ensure_nonzero(rand(iterations)), start_color: current_color.end_color, end_color: next_color)
        end
        frames = frames + current_color.rgb_colors_array
      end
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
  private

  def get_next_color(colors, idx)
    if (idx + 1) > (colors.length - 1)
      [color_string_to_class(colors[0]), 0]
    else
      [color_string_to_class(colors[idx + 1]), idx + 1]
    end
  end

  def color_string_to_class(color_string)
    Object.const_get("Color::RGB::#{color_string.capitalize}")
  end
end

class BlinkyStrip
  extend Color
  def initialize
    @blinky = BlinkyTape.new('/dev/cu.usbmodemFD131')
  end

  def send_color color_set
    color_set.each do |color|
      60.times do |light|
        send_pixel(color)
      end
      show
    end
  end

  def send_colors colors
    colors.each do |light|
      send_pixel(light)
    end
    show
  end

  def show
    @blinky.show
    @blinky.show
    @blinky.show
  end

  private
  def send_pixel color
    @blinky.send_pixel color.r, color.g, color.b
  end
end

