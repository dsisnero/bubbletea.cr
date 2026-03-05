require "../spec_helper"
require "../../lib/bubbles/src/bubbles"

private CHOICE_STYLE = Lipgloss::Style.new.padding_left(1).foreground(Lipgloss.color("241"))
private SAVE_TEXT_STYLE = Lipgloss::Style.new.foreground(Lipgloss.color("170"))
private QUIT_VIEW_STYLE = Lipgloss::Style.new.padding(1, 3).border(Lipgloss.rounded_border).border_foreground(Lipgloss.color("170"))

private struct PreventQuitParityKeymap
  property save : Bubbles::Key::Binding
  property quit : Bubbles::Key::Binding

  def initialize
    @save = Bubbles::Key.new_binding(
      Bubbles::Key.with_keys("ctrl+s"),
      Bubbles::Key.with_help("ctrl+s", "save")
    )
    @quit = Bubbles::Key.new_binding(
      Bubbles::Key.with_keys("esc", "ctrl+c"),
      Bubbles::Key.with_help("esc", "quit")
    )
  end
end

private class PreventQuitParityModel
  include Tea::Model

  getter? has_changes : Bool

  def initialize
    @textarea = Bubbles::Textarea.new
    @textarea.placeholder = "Only the best words"
    @textarea.focus

    @help = Bubbles::Help.new
    @keymap = PreventQuitParityKeymap.new
    @save_text = ""
    @has_changes = false
    @quitting = false
  end

  def init : Tea::Cmd?
    Bubbles::Textarea::Model.blink
  end

  def update(msg : Tea::Msg) : {Tea::Model, Tea::Cmd?}
    if @quitting
      return update_prompt_view(msg)
    end

    update_text_view(msg)
  end

  def view : Tea::View
    if @quitting
      if @has_changes
        text = Lipgloss.join_horizontal(Lipgloss::Position::Top, "You have unsaved changes. Quit without saving?", CHOICE_STYLE.render("[yN]"))
        return Tea.new_view(QUIT_VIEW_STYLE.render(text))
      end
      return Tea.new_view("Very important. Thank you.\n")
    end

    help_view = @help.short_help_view([@keymap.save, @keymap.quit])
    Tea.new_view("Type some important things.\n#{@textarea.view}\n #{SAVE_TEXT_STYLE.render(@save_text)}\n #{help_view}\n\n")
  end

  private def update_text_view(msg : Tea::Msg) : {Tea::Model, Tea::Cmd?}
    cmds = [] of Tea::Cmd?

    case msg
    when Tea::KeyPressMsg
      @save_text = ""
      case
      when Bubbles::Key.matches?(msg, @keymap.save)
        @save_text = "Changes saved!"
        @has_changes = false
      when Bubbles::Key.matches?(msg, @keymap.quit)
        @quitting = true
        return {self, Tea.quit}
      when msg.text.size > 0
        @save_text = ""
        @has_changes = true
        cmds << @textarea.focus unless @textarea.focused
      else
        cmds << @textarea.focus unless @textarea.focused
      end
    end

    @textarea, cmd = @textarea.update(msg)
    cmds << cmd
    {self, Tea.batch(cmds)}
  end

  private def update_prompt_view(msg : Tea::Msg) : {Tea::Model, Tea::Cmd?}
    case msg
    when Tea::KeyPressMsg
      if Bubbles::Key.matches?(msg, @keymap.quit) || msg.string == "y"
        @has_changes = false
        return {self, Tea.quit}
      end
      @quitting = false
    end

    {self, nil}
  end
end

private def prevent_quit_filter(tea_model : Tea::Model, msg : Tea::Msg) : Tea::Msg?
  return msg unless msg.is_a?(Tea::QuitMsg)

  model = tea_model.as(PreventQuitParityModel)
  model.has_changes? ? nil : msg
end

private def capture_prevent_quit_output : Bytes
  output = IO::Memory.new
  program = Bubbletea.new_program(
    PreventQuitParityModel.new,
    Tea.with_input(IO::Memory.new("")),
    Tea.with_output(output),
    Tea.without_signals,
    Tea.with_window_size(80, 24)
  )
  program.filter = ->(model : Tea::Model, msg : Tea::Msg) { prevent_quit_filter(model, msg) }

  spawn do
    sleep 120.milliseconds
    program.send(Tea.key('h'))
    sleep 40.milliseconds
    program.send(Tea.key('i'))
    sleep 40.milliseconds
    program.send(Tea.key(Tea::KeyEsc))
    sleep 60.milliseconds
    program.send(Tea.key('y'))
  end

  _model, err = program.run
  raise err.not_nil! if err
  output.to_slice
end

describe "examples/prevent_quit parity" do
  it "matches the saved Go golden output exactly" do
    actual = capture_prevent_quit_output
    expected = File.read("#{__DIR__}/golden/prevent_quit.go.golden").to_slice
    actual.should eq(expected)
  end
end
