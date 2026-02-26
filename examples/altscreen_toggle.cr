require "../src/bubbletea"

class AltScreenToggleModel
  include Bubbletea::Model

  def initialize(@altscreen = false, @quitting = false, @suspending = false)
  end

  def init : Bubbletea::Cmd?
    nil
  end

  def update(msg : Tea::Msg)
    case msg
    when Bubbletea::ResumeMsg
      @suspending = false
      {self, nil}
    when Bubbletea::KeyPressMsg
      case msg.string_with_mods
      when "q", "ctrl+c", "esc"
        @quitting = true
        {self, Bubbletea.quit}
      when "ctrl+z"
        @suspending = true
        {self, Bubbletea.suspend}
      when "space"
        @altscreen = !@altscreen
        {self, nil}
      else
        {self, nil}
      end
    else
      {self, nil}
    end
  end

  def view : Bubbletea::View
    if @suspending
      view = Bubbletea::View.new("")
      view.alt_screen = @altscreen
      return view
    end

    if @quitting
      view = Bubbletea::View.new("Bye!\n")
      view.alt_screen = @altscreen
      return view
    end

    mode = @altscreen ? " altscreen mode " : " inline mode "
    content = String.build do |io|
      io << "\n\n  You're in "
      io << mode
      io << "\n\n\n"
      io << "  space: switch modes • ctrl-z: suspend • q: exit\n"
    end
    view = Bubbletea::View.new(content)
    view.alt_screen = @altscreen
    view
  end
end

program = Bubbletea::Program.new(AltScreenToggleModel.new)
model, err = program.run
if err
  STDERR.puts "Error running program: #{err.message}"
  exit 1
end
model
