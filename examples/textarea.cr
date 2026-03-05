require "../lib/bubbles/src/bubbles"
require "lipgloss"

class TextareaErrMsg
  include Tea::Msg
  getter err : Exception

  def initialize(@err : Exception)
  end
end

class TextareaModel
  include Bubbletea::Model

  property textarea : Bubbles::Textarea::Model
  property err : Exception?

  def initialize
    ti = Bubbles::Textarea.new
    ti.placeholder = "Once upon a time..."
    ti.set_virtual_cursor(false)
    ti.set_styles(Bubbles::Textarea.default_styles(true))
    ti.focus

    @textarea = ti
    @err = nil
  end

  def init : Bubbletea::Cmd?
    Bubbletea.batch(Bubbles::Textarea::Model.blink, Tea.request_background_color)
  end

  def update(msg : Tea::Msg)
    cmds = [] of Tea::Cmd?

    case msg
    when Tea::BackgroundColorMsg
      @textarea.set_styles(Bubbles::Textarea.default_styles(msg.is_dark?))
    when Tea::KeyPressMsg
      case msg.keystroke
      when "esc"
        @textarea.blur if @textarea.focused
      when "ctrl+c"
        return {self, Tea.quit}
      else
        unless @textarea.focused
          cmd = @textarea.focus
          cmds << cmd
        end
      end
    when TextareaErrMsg
      @err = msg.err
      return {self, nil}
    end

    @textarea, cmd = @textarea.update(msg)
    cmds << cmd
    {self, Tea.batch(cmds)}
  end

  def header_view : String
    "Tell me a story.\n"
  end

  def view : Bubbletea::View
    footer = "\n(ctrl+c to quit)\n"

    cursor = nil.as(Tea::Cursor?)
    unless @textarea.virtual_cursor?
      if c = @textarea.cursor
        offset = Lipgloss.height(header_view)
        c.y += offset
        cursor = c
      end
    end

    body = [header_view, @textarea.view, footer].join("\n")
    v = Bubbletea::View.new(body)
    v.cursor = cursor
    v
  end
end

unless ENV["BUBBLETEA_EXAMPLE_DISABLE_MAIN"]? == "1"
  program = Bubbletea::Program.new(TextareaModel.new)
  _model, err = program.run
  if err
    STDERR.puts "Error running program: #{err.message}"
    exit 1
  end
end
