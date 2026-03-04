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
  Tea.exec_process(editor, callback: ->(err : Exception?) {
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
      case msg.keystroke
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

    view.content = "Press 'e' to open your EDITOR.\nPress 'a' to toggle the altscreen\nPress 'q' to quit.\n"
    view
  end
end

unless ENV["BUBBLETEA_EXAMPLE_DISABLE_MAIN"]? == "1"
  unless STDIN.tty? && STDOUT.tty?
    STDERR.puts "Error running program: bubbletea: error opening TTY: stdin/stdout are not TTY"
    exit 1
  end

  # Main
  model = Model.new
  program = Tea::Program.new(model)

  _, err = program.run

  if err
    puts "Error running program: #{err}"
    exit 1
  end
end
