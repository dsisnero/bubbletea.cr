require "../src/bubbletea"
require "lipgloss"

BODY_STYLE = Lipgloss::Style.new.padding(1, 2)

class ProgressBarModel
  include Bubbletea::Model

  def initialize
    @value = 50
    @width = 80
    @state = Tea::ProgressBarState::Indeterminate
  end

  def init : Bubbletea::Cmd?
    nil
  end

  def update(msg : Tea::Msg)
    case msg
    when Bubbletea::WindowSizeMsg
      @width = msg.width
    when Bubbletea::KeyPressMsg
      case msg.keystroke
      when "q", "ctrl+c"
        return {self, Bubbletea.quit}
      when "up", "k"
        @value += 10 if @value < 100
      when "down", "j"
        @value -= 10 if @value > 0
      when "left", "h"
        @state = Tea::ProgressBarState.from_value?(@state.value - 1) || @state if @state.value > 0
      when "right", "l"
        @state = Tea::ProgressBarState.from_value?(@state.value + 1) || @state if @state.value < 4
      end
    end

    {self, nil}
  end

  def view : Bubbletea::View
    body_padding = BODY_STYLE.horizontal_padding
    content = BODY_STYLE
      .width(@width - body_padding)
      .render("This demo requires a terminal emulator that supports an indeterminate progress bar, such a Windows Terminal or Ghostty. In other terminals (including tmux in a supporting terminal) nothing will happen.\n\nPress up/down to change value, left/right to change state, q to quit.")
    v = Bubbletea::View.new(content)
    v.progress_bar = Tea.new_progress_bar(@state, @value.to_f)
    v
  end
end

unless ENV["BUBBLETEA_EXAMPLE_DISABLE_MAIN"]? == "1"
  unless STDIN.tty? && STDOUT.tty?
    STDERR.puts "Error running program: bubbletea: error opening TTY: stdin/stdout are not TTY"
    exit 1
  end
  program = Bubbletea::Program.new(ProgressBarModel.new)
  _model, err = program.run
  if err
    STDERR.puts "Error: #{err.message}"
    exit 1
  end
end
