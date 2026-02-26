require "../src/bubbletea"
require "lipgloss"

class TabsModel
  include Bubbletea::Model

  def initialize
    @tabs = ["Lip Gloss", "Blush", "Eye Shadow", "Mascara", "Foundation"]
    @contents = ["Lip Gloss Tab", "Blush Tab", "Eye Shadow Tab", "Mascara Tab", "Foundation Tab"]
    @active_tab = 0
  end

  def init : Bubbletea::Cmd?
    nil
  end

  def update(msg : Tea::Msg)
    case msg
    when Bubbletea::KeyPressMsg
      case msg.string_with_mods
      when "ctrl+c", "q"
        return {self, Bubbletea.quit}
      when "right", "l", "n", "tab"
        @active_tab = {@active_tab + 1, @tabs.size - 1}.min
      when "left", "h", "p", "shift+tab"
        @active_tab = {@active_tab - 1, 0}.max
      end
    end

    {self, nil}
  end

  def view : Bubbletea::View
    rendered_tabs = @tabs.map_with_index do |tab, i|
      if i == @active_tab
        "[#{tab}]"
      else
        " #{tab} "
      end
    end

    doc = String.build do |io|
      io << rendered_tabs.join(" ")
      io << "\n\n"
      io << @contents[@active_tab]
      io << "\n\n"
      io << "h/left and l/right switch tabs • q quits"
    end

    Bubbletea::View.new(Lipgloss::Style.new.padding(1, 2).render(doc))
  end
end

program = Bubbletea::Program.new(TabsModel.new)
_model, err = program.run
if err
  STDERR.puts "Error running program: #{err.message}"
  exit 1
end
