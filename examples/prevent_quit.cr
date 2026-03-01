require "../src/bubbletea"

class PreventQuitModel
  include Bubbletea::Model
  getter? has_changes : Bool

  def initialize
    @text = ""
    @save_text = ""
    @has_changes = false
    @quitting = false
  end

  def init : Bubbletea::Cmd?
    Bubbletea.tick(500.milliseconds, ->(_t : Time) { Bubbletea["blink"].as(Tea::Msg?) })
  end

  def update(msg : Tea::Msg)
    if @quitting
      return update_prompt_view(msg)
    end
    update_text_view(msg)
  end

  def view : Bubbletea::View
    if @quitting
      if @has_changes
        return Bubbletea::View.new("You have unsaved changes. Quit without saving? [yN]")
      end
      return Bubbletea::View.new("Very important. Thank you.\n")
    end

    Bubbletea::View.new(
      "Type some important things.\n" +
      @text + "\n " + @save_text + "\n ctrl+s: save • esc: quit\n\n"
    )
  end

  private def update_text_view(msg : Tea::Msg)
    case msg
    when Bubbletea::KeyPressMsg
      @save_text = ""
      case msg.keystroke
      when "ctrl+s"
        @save_text = "Changes saved!"
        @has_changes = false
      when "esc", "ctrl+c"
        @quitting = true
        return {self, Bubbletea.quit}
      when "backspace"
        @text = @text[0...-1] unless @text.empty?
        @has_changes = true
      when "space"
        @text += " "
        @has_changes = true
      else
        if rune = msg.rune
          @text += rune.to_s
          @has_changes = true
        end
      end
    end
    {self, nil}
  end

  private def update_prompt_view(msg : Tea::Msg)
    case msg
    when Bubbletea::KeyPressMsg
      if msg.keystroke.in?({"esc", "ctrl+c", "y"})
        @has_changes = false
        return {self, Bubbletea.quit}
      end
      @quitting = false
    end

    {self, nil}
  end
end

filter = ->(model : Tea::Model, msg : Tea::Msg) : Tea::Msg? {
  if msg.is_a?(Tea::QuitMsg)
    m = model.as(PreventQuitModel)
    m.has_changes? ? nil : msg
  else
    msg
  end
}

program = Bubbletea::Program.new(PreventQuitModel.new)
program.filter = filter
_model, err = program.run
if err
  STDERR.puts err.message
  exit 1
end
