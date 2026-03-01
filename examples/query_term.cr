require "../src/bubbletea"

class QueryTermModel
  include Bubbletea::Model

  def initialize
    @input = ""
    @err = nil.as(String?)
  end

  def init : Bubbletea::Cmd?
    nil
  end

  def update(msg : Tea::Msg)
    case msg
    when Bubbletea::KeyPressMsg
      @err = nil
      case msg.keystroke
      when "ctrl+c"
        return {self, Bubbletea.quit}
      when "enter"
        seq = @input
        @input = ""

        unless seq.starts_with?("\e") || seq.starts_with?("\u001b")
          @err = "sequence is not an ANSI escape sequence"
          return {self, nil}
        end

        return {self, Tea.raw(seq)}
      when "backspace"
        @input = @input[0...-1] unless @input.empty?
      when "space"
        @input += " "
      else
        if rune = msg.rune
          @input += rune.to_s
        end
      end
    else
      if name = msg.class.name
        if !name.empty? && name[0]?.try(&.ascii_uppercase?)
          return {self, Bubbletea.printf("Received message: %s %+v", name, msg.to_s)}
        end
      end
    end

    {self, nil}
  end

  def view : Bubbletea::View
    s = String.build do |io|
      io << @input
      io << "\n\nError: #{@err}" if @err
      io << "\n\nPress ctrl+c to quit, enter to write the sequence to terminal"
    end

    v = Bubbletea::View.new(s)
    v.cursor = Bubbletea::Cursor.new(@input.size, 0)
    v
  end
end

program = Bubbletea::Program.new(QueryTermModel.new)
_model, err = program.run
if err
  STDERR.puts err.message
  exit 1
end
