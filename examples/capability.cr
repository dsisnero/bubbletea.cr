require "../src/bubbletea"

class CapabilityModel
  include Bubbletea::Model

  def initialize(@input = "", @width = 0, @last = "")
  end

  def init : Bubbletea::Cmd?
    nil
  end

  def update(msg : Tea::Msg)
    case msg
    when Bubbletea::WindowSizeMsg
      @width = msg.width
      {self, nil}
    when Bubbletea::CapabilityMsg
      @last = "Got capability: #{msg}"
      {self, Bubbletea.println(@last)}
    when Bubbletea::KeyPressMsg
      case msg.string_with_mods
      when "ctrl+c", "esc"
        {self, Bubbletea.quit}
      when "enter"
        query = @input.empty? ? "RGB" : @input
        @input = ""
        {self, Tea.request_capability(query)}
      when "backspace"
        @input = @input[0...-1] unless @input.empty?
        {self, nil}
      else
        if rune = msg.rune
          @input += rune.to_s
        end
        {self, nil}
      end
    else
      {self, nil}
    end
  end

  def view : Bubbletea::View
    width = {@width, 60}.min
    width = 60 if width <= 0
    lines = [] of String
    lines << "Query for terminal capabilities (e.g. TN, RGB, cols)."
    lines << "Input: #{@input}"
    lines << ""
    lines << "Press enter to request capability, or ctrl+c to quit."
    lines << ""
    lines << @last unless @last.empty?
    Bubbletea::View.new(lines.join("\n")[0, width * 6]? || lines.join("\n"))
  end
end

program = Bubbletea::Program.new(CapabilityModel.new)
_model, err = program.run
if err
  STDERR.puts "Uh oh: #{err.message}"
  exit 1
end
