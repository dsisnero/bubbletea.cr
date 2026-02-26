# External Editor Example
# Ported from Go: vendor/examples/exec/main.go
# Shows how to execute external commands (like an editor).

require "../src/bubbletea"

# Message sent when editor finishes
struct EditorFinishedMsg
  include Tea::Msg
  property error : Exception?

  def initialize(@error : Exception?)
  end
end

# Open the system editor
private def open_editor : Tea::Cmd
  editor = ENV["EDITOR"]? || "vim"
  process = Process.new(editor)
  Tea.exec_process(process, ->( err : Exception?) {
    EditorFinishedMsg.new(err).as(Tea::Msg?)
  })
end

# Model tracks state
struct Model
  include Tea::Model

  property altscreen_active : Bool = false
  property error : Exception? = nil

  def initialize
  end

  def init : Tea::Cmd?
    nil
  end

  def update(msg : Tea::Msg) : Tuple(Tea::Model, Tea::Cmd?)
    case msg
    when Tea::KeyPressMsg
      case msg.to_s
      when "a"
        @altscreen_active = !@altscreen_active
        return {self, nil}
      when "e"
        return {self, open_editor}
      when "ctrl+c", "q"
        return {self, Tea.quit}
      end
    when EditorFinishedMsg
      if msg.error
        @error = msg.error
        return {self, Tea.quit}
      end
    end

    {self, nil}
  end

  def view : Tea::View
    view = Tea::View.new("")
    view.alt_screen = @altscreen_active

    if @error
      view.content = "Error: #{@error}\n"
      return view
    end

    lines = [] of String
    lines << "Press 'e' to open your EDITOR."
    lines << "Press 'a' to toggle the altscreen"
    lines << "Press 'q' to quit."

    view.content = lines.join("\n")
    view
  end
end

# Main
model = Model.new
program = Tea::Program.new(model)

_, err = program.run

if err
  puts "Error running program: #{err}"
  exit 1
end