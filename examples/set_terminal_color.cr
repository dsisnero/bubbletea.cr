require "../src/bubbletea"

enum ColorType
  Foreground
  Background
  Cursor

  def to_s : String
    case self
    when .foreground?
      "Foreground"
    when .background?
      "Background"
    when .cursor?
      "Cursor"
    else
      "Unknown"
    end
  end
end

enum SetColorState
  Choose
  Input
end

class SetTerminalColorModel
  include Bubbletea::Model

  def initialize
    @input = ""
    @choice = nil.as(ColorType?)
    @state = SetColorState::Choose
    @choice_index = 0
    @err = nil.as(String?)
    @fg = nil.as(Colorful::Color?)
    @bg = nil.as(Colorful::Color?)
    @cc = nil.as(Colorful::Color?)
  end

  def init : Bubbletea::Cmd?
    Bubbletea.tick(500.milliseconds, ->(_t : Time) { Bubbletea["blink"].as(Tea::Msg?) })
  end

  def update(msg : Tea::Msg)
    return {self, nil} unless msg.is_a?(Bubbletea::KeyPressMsg)

    key = msg.keystroke
    return {self, Bubbletea.quit} if key.in?({"ctrl+c", "q"})

    case @state
    when SetColorState::Choose
      case key
      when "j", "down"
        @choice_index = (@choice_index + 1) % 3
      when "k", "up"
        @choice_index = (@choice_index - 1) % 3
      when "enter"
        @state = SetColorState::Input
        @choice = {ColorType::Foreground, ColorType::Background, ColorType::Cursor}[@choice_index]
      end
    when SetColorState::Input
      case key
      when "esc"
        reset_choice
      when "enter"
        if color = parse_hex(@input)
          case @choice
          when ColorType::Foreground
            @fg = color
          when ColorType::Background
            @bg = color
          when ColorType::Cursor
            @cc = color
          end
          @err = nil
          @input = ""
          reset_choice
        else
          @err = "invalid hex color"
        end
      when "backspace"
        @input = @input[0...-1] unless @input.empty?
      else
        if r = msg.rune
          @input += r.to_s
        end
      end
    end

    {self, nil}
  end

  def view : Bubbletea::View
    lines = [] of String

    if @state.choose?
      lines << "Choose a terminal-wide color to set."
      lines << ""
      {ColorType::Foreground, ColorType::Background, ColorType::Cursor}.each_with_index do |c, i|
        prefix = i == @choice_index ? " > " : "   "
        lines << "#{prefix}#{c}"
      end
    else
      lines << "Enter a color in hex format:"
      lines << ""
      lines << @input
    end

    lines << ""
    lines << "Error: #{@err}" if @err
    lines << "Press q to quit#{@state.choose? ? ", j/k to move, and enter to select" : ", and enter to submit, esc to go back"}"

    v = Bubbletea::View.new(lines.join("\n"))
    v.background_color = @bg
    v.foreground_color = @fg

    if @state.input?
      cursor = Bubbletea::Cursor.new(@input.size, 2)
      cursor.color = @cc
      v.cursor = cursor
    end

    v
  end

  private def reset_choice
    @choice = nil
    @choice_index = 0
    @state = SetColorState::Choose
  end

  private def parse_hex(value : String) : Colorful::Color?
    s = value.strip
    s = s[1..] if s.starts_with?("#")
    return nil unless s.size == 6

    r = s[0, 2].to_i?(16)
    g = s[2, 2].to_i?(16)
    b = s[4, 2].to_i?(16)
    return nil unless r && g && b

    Colorful::Color.new(r / 255.0, g / 255.0, b / 255.0)
  end
end

program = Bubbletea::Program.new(SetTerminalColorModel.new)
_model, err = program.run
if err
  STDERR.puts "Error running program: #{err.message}"
  exit 1
end
