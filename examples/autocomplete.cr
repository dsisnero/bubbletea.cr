require "../src/bubbletea"

struct AutoCompleteKeymap
  getter complete = "tab"
  getter next_key = "ctrl+n"
  getter prev_key = "ctrl+p"
  getter quit = "esc"

  def short_help : Array(String)
    [complete, next_key, prev_key, quit]
  end

  def full_help : Array(Array(String))
    [short_help]
  end
end

class AutoCompleteModel
  include Bubbletea::Model

  def initialize(@input = "", @matches = [] of String, @keymap = AutoCompleteKeymap.new)
  end

  def init : Bubbletea::Cmd?
    # In Go this batches async repo fetch + textinput blink.
    # Keep the command pipeline active with a no-op timer tick.
    Tea.tick(1.millisecond) { Bubbletea["ready"] }
  end

  def update(msg : Tea::Msg)
    case msg
    when Bubbletea::KeyPressMsg
      case msg.string_with_mods
      when "esc", "ctrl+c", "enter"
        return {self, Bubbletea.quit}
      when "backspace"
        @input = @input[0...-1] unless @input.empty?
      when "space"
        @input += " "
      else
        if rune = msg.rune
          @input += rune.to_s
        end
      end
      @matches = filter_matches(@input)
    end

    {self, nil}
  end

  def view : Bubbletea::View
    lines = [] of String
    lines << "Enter a Charm repo:"
    lines << "charmbracelet/#{@input}"
    if @matches.empty?
      lines << ""
      lines << "No matches yet."
    else
      lines << ""
      lines << "Suggestions:"
      @matches.first(5).each { |m| lines << "  - #{m}" }
    end
    lines << ""
    lines << "Keys: #{keymap.short_help.join(" • ")}"
    Bubbletea::View.new(lines.join("\n"))
  end

  private getter keymap : AutoCompleteKeymap

  private def filter_matches(input : String) : Array(String)
    return [] of String if input.empty?
    repos = %w[
      bubbletea
      bubbles
      lipgloss
      glamour
      wish
      ssh
      colorful
      log
    ]
    repos.select { |r| r.starts_with?(input.downcase) }
  end
end

program = Bubbletea::Program.new(AutoCompleteModel.new)
_model, err = program.run
if err
  STDERR.puts "Error running program: #{err.message}"
  exit 1
end
