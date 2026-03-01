# Focus Blur Example
# Ported from Go: vendor/examples/focus-blur/main.go
# Shows how to handle terminal focus and blur events.

require "../src/bubbletea"

# Model tracks focus state
struct Model
  include Tea::Model

  property focused : Bool = true
  property reporting : Bool = true

  def initialize(@focused : Bool = true, @reporting : Bool = true)
  end

  def init : Tea::Cmd?
    nil
  end

  def update(msg : Tea::Msg) : Tuple(Tea::Model, Tea::Cmd?)
    case msg
    when Tea::FocusMsg
      @focused = true
    when Tea::BlurMsg
      @focused = false
    when Tea::KeyPressMsg
      case msg.to_s
      when "t"
        @reporting = !@reporting
      when "ctrl+c", "q"
        return {self, Tea.quit}
      end
    end

    {self, nil}
  end

  def view : Tea::View
    view = Tea::View.new("")

    status = @reporting ? "enabled" : "disabled"
    lines = [] of String
    lines << "Hi. Focus report is currently #{status}."
    lines << ""

    if @reporting
      if @focused
        lines << "This program is currently focused!"
      else
        lines << "This program is currently blurred!"
      end
    end

    lines << ""
    lines << "To quit sooner press ctrl-c, or t to toggle focus reporting..."

    view.content = lines.join("\n")
    view.report_focus = @reporting
    view
  end
end

# Main
model = Model.new(focused: true, reporting: true)
program = Tea::Program.new(model)

_, err = program.run

if err
  puts "Error: #{err}"
  exit 1
end
