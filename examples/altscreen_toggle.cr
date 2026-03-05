require "../src/bubbletea"
require "lipgloss"

class AltScreenToggleModel
  include Bubbletea::Model

  KEYWORD_STYLE = Lipgloss::Style.new.foreground("204").background("235")
  HELP_STYLE    = Lipgloss::Style.new.foreground("241")

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
      case msg.keystroke
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
      io << KEYWORD_STYLE.render(mode)
      io << "\n\n\n"
      io << HELP_STYLE.render("  space: switch modes • ctrl-z: suspend • q: exit\n")
    end
    view = Bubbletea::View.new(content)
    view.alt_screen = @altscreen
    view
  end
end

unless ENV["BUBBLETEA_EXAMPLE_DISABLE_MAIN"]? == "1"
  program = Bubbletea::Program.new(AltScreenToggleModel.new)
  model, err = program.run
  if err
    STDERR.puts "Error running program: #{err.message}"
    exit 1
  end
  model
end
