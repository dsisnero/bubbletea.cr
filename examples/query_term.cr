require "../src/bubbletea"
require "../lib/bubbles/src/bubbles"

class QueryTermModel
  include Bubbletea::Model

  @input : Bubbles::TextInput::Model
  @err : Exception?

  def initialize
    ti = Bubbles::TextInput.new
    ti.focus
    ti.char_limit = 156
    ti.set_width(20)
    ti.set_virtual_cursor(false)

    @input = ti
    @err = nil.as(Exception?)
  end

  def init : Bubbletea::Cmd?
    nil
  end

  def update(msg : Tea::Msg)
    cmds = [] of Tea::Cmd

    case msg
    when Tea::KeyPressMsg
      @err = nil

      case msg.keystroke
      when "ctrl+c"
        return {self, Bubbletea.quit}
      when "enter"
        # Match Go's strconv.Unquote behavior over a quoted string.
        quoted = "\"#{@input.value}\""
        seq = begin
          unquote(quoted)
        rescue ex
          @err = ex
          return {self, nil}
        end

        unless seq.starts_with?('\e')
          @err = Exception.new("sequence is not an ANSI escape sequence")
          return {self, nil}
        end

        @input.set_value("")
        return {self, -> { STDOUT << seq; STDOUT.flush; nil.as(Tea::Msg?) }}
      end
    else
      if formatted = format_exported_message(msg)
        cmds << Bubbletea.printf("Received message: %s", formatted)
      end
    end

    @input, cmd = @input.update(msg)
    cmds << cmd if cmd

    {self, Bubbletea.batch(cmds)}
  end

  def view : Bubbletea::View
    s = String.build do |io|
      io << @input.view
      io << "\n\nError: #{@err.not_nil!.message}" if @err
      io << "\n\nPress ctrl+c to quit, enter to write the sequence to terminal"
    end

    v = Bubbletea::View.new(s)
    v.cursor = @input.cursor
    v
  end

  private def format_exported_message(msg : Tea::Msg) : String?
    case msg
    when Tea::PrintLineMsg,
         Tea::RequestBackgroundColorMsg,
         Tea::RequestForegroundColorMsg,
         Tea::RequestCursorColorMsg,
         Tea::RequestCapabilityMsg,
         Tea::TerminalVersionRequestMsg,
         Tea::WindowSizeRequestMsg,
         Tea::SetWindowTitleMsg
      return nil
    when Tea::ColorProfileMsg
      return "tea.ColorProfileMsg #{msg.profile}"
    when Tea::WindowSizeMsg
      return "tea.WindowSizeMsg {Width:#{msg.width} Height:#{msg.height}}"
    when Tea::EnvMsg
      return "tea.EnvMsg [#{msg.environ.items.join(' ')}]"
    end

    if name = msg.class.name
      type_name = name.split("::").last? || name
      return nil unless !type_name.empty? && type_name[0]?.try(&.ascii_uppercase?)
      return "tea.#{type_name} #{msg}"
    end

    nil
  end

  private def unquote(s : String) : String
    raise Exception.new("invalid quoted string") unless s.size >= 2 && s[0] == '"' && s[-1] == '"'
    body = s[1...-1]
    io = IO::Memory.new
    i = 0

    while i < body.size
      ch = body[i]
      if ch != '\\'
        io << ch
        i += 1
        next
      end

      raise Exception.new("invalid escape") if i + 1 >= body.size
      esc = body[i + 1]
      case esc
      when '"', '\\'
        io << esc
        i += 2
      when 'a'
        io << '\a'
        i += 2
      when 'b'
        io << '\b'
        i += 2
      when 'e'
        io << '\e'
        i += 2
      when 'f'
        io << '\f'
        i += 2
      when 'n'
        io << '\n'
        i += 2
      when 'r'
        io << '\r'
        i += 2
      when 't'
        io << '\t'
        i += 2
      when 'v'
        io << '\v'
        i += 2
      when 'x'
        raise Exception.new("invalid hex escape") if i + 3 >= body.size
        hex = body[(i + 2)..(i + 3)]
        value = hex.to_i(16)
        io << value.chr
        i += 4
      else
        raise Exception.new("unsupported escape: \\#{esc}")
      end
    end

    io.to_s
  end
end

unless ENV["BUBBLETEA_EXAMPLE_DISABLE_MAIN"]? == "1"
  program = Bubbletea::Program.new(QueryTermModel.new)
  _model, err = program.run
  if err
    STDERR.puts err.message
    exit 1
  end
end
