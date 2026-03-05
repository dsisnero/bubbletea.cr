require "../spec_helper"
require "../../lib/bubbles/src/bubbles"

private enum ParityColorType
  None
  Foreground
  Background
  Cursor
end

private enum ParityState
  Choose
  Input
end

private class SetTerminalColorParityModel
  include Tea::Model

  def initialize
    @ti = Bubbles::TextInput.new
    @ti.placeholder = "#ff00ff"
    @ti.char_limit = 156
    @ti.set_width(20)
    @ti.set_virtual_cursor(false)

    @choice = ParityColorType::None
    @state = ParityState::Choose
    @choice_index = 0
    @err = nil.as(Exception?)
    @fg = nil.as(Colorful::Color?)
    @bg = nil.as(Colorful::Color?)
    @cc = nil.as(Colorful::Color?)
  end

  def init : Tea::Cmd?
    -> { Bubbles::TextInput.blink.as(Tea::Msg?) }
  end

  def update(msg : Tea::Msg) : {Tea::Model, Tea::Cmd?}
    case msg
    when Tea::KeyPressMsg
      case msg.string
      when "ctrl+c", "q"
        return {self, Tea.quit}
      end

      case @state
      when .choose?
        @ti.blur
        case msg.string
        when "j", "down"
          @choice_index += 1
          @choice_index = 0 if @choice_index > 2
        when "k", "up"
          @choice_index -= 1
          @choice_index = 2 if @choice_index < 0
        when "enter"
          @state = ParityState::Input
          @ti.focus
          @choice = case @choice_index
                    when 0 then ParityColorType::Foreground
                    when 1 then ParityColorType::Background
                    else        ParityColorType::Cursor
                    end
        end
      when .input?
        @ti.focus
        case msg.string
        when "esc"
          @choice = ParityColorType::None
          @choice_index = 0
          @state = ParityState::Choose
          @err = nil
          @ti.blur
        when "enter"
          val = @ti.value
          begin
            col = Colorful::Color.hex(val)
            @err = nil
            choice = @choice
            @choice = ParityColorType::None
            @choice_index = 0
            @state = ParityState::Choose
            @ti.reset

            case choice
            when .foreground? then @fg = col
            when .background? then @bg = col
            when .cursor?     then @cc = col
            else
            end
          rescue ex
            @err = ex
          end
          @ti.blur
        else
          @ti, cmd = @ti.update(msg)
          return {self, cmd}
        end
      end
    end

    {self, nil}
  end

  def view : Tea::View
    s = String.build do |io|
      instructions = Lipgloss::Style.new.width(40).render("Choose a terminal-wide color to set. All settings will be cleared on exit.")

      case @state
      when .choose?
        io << instructions << "\n\n"
        {ParityColorType::Foreground, ParityColorType::Background, ParityColorType::Cursor}.each_with_index do |c, i|
          io << (i == @choice_index ? " > " : "   ")
          io << c.to_s
          io << "\n"
        end
      when .input?
        io << "Enter a color in hex format:\n\n"
        io << @ti.view
        io << "\n"
      end

      if err = @err
        io << "\nError: " << err.message
      end

      io << "\nPress q to quit"
      case @state
      when .choose?
        io << ", j/k to move, and enter to select"
      when .input?
        io << ", and enter to submit, esc to go back"
      end
      io << "\n"
    end

    v = Tea.new_view(s)
    if @ti.focused?
      if cursor = @ti.cursor
        cursor.y += 2
        cursor.color = @cc
        v.cursor = cursor
      end
    end
    v.background_color = @bg if @bg
    v.foreground_color = @fg if @fg
    v
  end
end

private def capture_set_terminal_color_output : Bytes
  output = IO::Memory.new
  program = Bubbletea.new_program(
    SetTerminalColorParityModel.new,
    Tea.with_input(IO::Memory.new("")),
    Tea.with_output(output),
    Tea.without_signals,
    Tea.with_window_size(80, 24)
  )

  spawn do
    sleep 120.milliseconds
    # Foreground -> violet
    sleep 40.milliseconds
    program.send(Tea.key(Tea::KeyEnter))
    sleep 40.milliseconds
    "#6b50ff".each_char do |ch|
      program.send(Tea.key(ch))
    end
    sleep 40.milliseconds
    program.send(Tea.key(Tea::KeyEnter))

    # Background -> green
    sleep 40.milliseconds
    program.send(Tea.key(Tea::KeyDown))
    sleep 40.milliseconds
    program.send(Tea.key(Tea::KeyEnter))
    sleep 40.milliseconds
    "#00ff00".each_char do |ch|
      program.send(Tea.key(ch))
    end
    sleep 40.milliseconds
    program.send(Tea.key(Tea::KeyEnter))

    # Cursor -> gray
    sleep 40.milliseconds
    program.send(Tea.key(Tea::KeyDown))
    sleep 40.milliseconds
    program.send(Tea.key(Tea::KeyDown))
    sleep 40.milliseconds
    program.send(Tea.key(Tea::KeyEnter))
    sleep 40.milliseconds
    "#808080".each_char do |ch|
      program.send(Tea.key(ch))
    end
    sleep 40.milliseconds
    program.send(Tea.key(Tea::KeyEnter))
    sleep 40.milliseconds
    program.send(Tea.key('q'))
  end

  _model, err = program.run
  raise err.not_nil! if err
  output.to_slice
end

describe "examples/set_terminal_color parity" do

  it "matches the saved Go golden output exactly" do
    actual = capture_set_terminal_color_output
    expected = File.read("#{__DIR__}/golden/set_terminal_color.go.golden").to_slice
    actual.should eq(expected)
  end
end
