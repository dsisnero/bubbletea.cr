require "../spec_helper"
require "../../lib/bubbles/src/bubbles"
require "lipgloss"

private struct AutoCompleteReposMsg
  include Tea::Msg
  getter repos : Array(String)

  def initialize(@repos : Array(String))
  end
end

private struct AutoCompleteKeymap
  include Bubbles::Help::KeyMap

  property complete : Bubbles::Key::Binding
  property next_key : Bubbles::Key::Binding
  property prev_key : Bubbles::Key::Binding
  property quit : Bubbles::Key::Binding

  def initialize
    @complete = Bubbles::Key.new_binding(
      Bubbles::Key.with_keys("tab"),
      Bubbles::Key.with_help("tab", "complete"),
      Bubbles::Key.with_disabled,
    )
    @next_key = Bubbles::Key.new_binding(
      Bubbles::Key.with_keys("ctrl+n"),
      Bubbles::Key.with_help("ctrl+n", "next"),
      Bubbles::Key.with_disabled,
    )
    @prev_key = Bubbles::Key.new_binding(
      Bubbles::Key.with_keys("ctrl+p"),
      Bubbles::Key.with_help("ctrl+p", "prev"),
      Bubbles::Key.with_disabled,
    )
    @quit = Bubbles::Key.new_binding(
      Bubbles::Key.with_keys("enter", "ctrl+c", "esc"),
      Bubbles::Key.with_help("esc", "quit"),
    )
  end

  def short_help : Array(Bubbles::Key::Binding)
    [@complete, @next_key, @prev_key, @quit]
  end

  def full_help : Array(Array(Bubbles::Key::Binding))
    [short_help]
  end
end

private class AutoCompleteParityModel
  include Tea::Model

  def initialize
    @text_input = Bubbles::TextInput.new
    @text_input.prompt = "charmbracelet/"

    styles = @text_input.styles
    styles.focused.prompt = Lipgloss::Style.new.foreground(Lipgloss.color("63")).margin_left(2)
    styles.cursor.color = "63"
    @text_input.set_styles(styles)

    @text_input.set_virtual_cursor(false)
    @text_input.focus
    @text_input.char_limit = 50
    @text_input.set_width(20)
    @text_input.show_suggestions = true

    @keymap = AutoCompleteKeymap.new
    @help = Bubbles::Help.new
  end

  def init : Tea::Cmd?
    Tea.batch(
      -> { AutoCompleteReposMsg.new(["bubbletea", "bubbles", "lipgloss"]).as(Tea::Msg?) },
      -> { Bubbles::TextInput.blink.as(Tea::Msg?) }
    )
  end

  def update(msg : Tea::Msg) : {Tea::Model, Tea::Cmd?}
    case msg
    when AutoCompleteReposMsg
      @text_input.set_suggestions(msg.repos)
    when Tea::KeyPressMsg
      if Bubbles::Key.matches?(msg, @keymap.quit)
        return {self, Tea.quit}
      end
    end

    @text_input, cmd = @text_input.update(msg)

    has_choices = @text_input.matched_suggestions.size > 1
    @keymap.complete.set_enabled(has_choices)
    @keymap.next_key.set_enabled(has_choices)
    @keymap.prev_key.set_enabled(has_choices)

    {self, cmd}
  end

  def view : Tea::View
    if @text_input.available_suggestions.empty?
      return Tea.new_view("One sec, we're fetching completions...")
    end

    view = Tea.new_view(Lipgloss.join_vertical(
      Lipgloss::Position::Left,
      header_view,
      @text_input.view,
      footer_view
    ))

    if cursor = @text_input.cursor
      cursor.y += Lipgloss.height(header_view)
      view.cursor = cursor
    end

    view
  end

  private def header_view : String
    "Enter a Charm™ repo:\n"
  end

  private def footer_view : String
    "\n" + @help.view(@keymap)
  end
end

private def capture_autocomplete_output : Bytes
  output = IO::Memory.new
  program = Bubbletea.new_program(
    AutoCompleteParityModel.new,
    Tea.with_input(IO::Memory.new("")),
    Tea.with_output(output),
    Tea.without_signals,
    Tea.with_window_size(80, 24),
  )

  spawn do
    sleep 120.milliseconds
    program.send(Tea.key('b'))
    sleep 40.milliseconds
    program.send(Tea.key('u'))
    sleep 40.milliseconds
    program.send(Tea.key(Tea::KeyTab))
    sleep 40.milliseconds
    program.send(Tea.key(Tea::KeyEnter))
  end

  _model, err = program.run
  raise err.not_nil! if err
  output.to_slice
end

describe "examples/autocomplete parity" do
  it "matches the saved Go golden output exactly" do
    actual = capture_autocomplete_output
    expected = File.read("#{__DIR__}/golden/autocomplete.go.golden").to_slice
    actual.should eq(expected)
  end
end
