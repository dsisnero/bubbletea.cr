require "../lib/bubbles/src/bubbles"
require "lipgloss"

class ChatModel
  include Tea::Model

  @viewport : Bubbles::Viewport::Model
  @textarea : Bubbles::Textarea::Model
  @messages : Array(String)
  @sender_style : Lipgloss::Style

  def initialize
    ta = Bubbles::Textarea.new
    ta.placeholder = "Send a message..."
    ta.set_virtual_cursor(false)
    ta.focus
    ta.prompt = "┃ "
    ta.char_limit = 280
    ta.set_width(30)
    ta.set_height(3)

    # Remove cursor-line styling, matching Go chat example.
    s = ta.styles
    s.focused.cursor_line = Lipgloss::Style.new
    ta.styles = s
    ta.show_line_numbers = false

    km = ta.key_map
    km.insert_newline.set_enabled(false)
    ta.key_map = km

    @viewport = Bubbles::Viewport.new(
      Bubbles::Viewport.with_width(30),
      Bubbles::Viewport.with_height(5)
    )
    @viewport.set_content("Welcome to the chat room!\nType a message and press Enter to send.")
    @viewport.key_map.left.set_enabled(false)
    @viewport.key_map.right.set_enabled(false)
    @textarea = ta
    @messages = [] of String
    @sender_style = Lipgloss::Style.new.foreground(Lipgloss.color("5"))
  end

  def init : Tea::Cmd?
    Bubbles::Textarea::Model.blink
  end

  def update(msg : Tea::Msg)
    case msg
    when Tea::WindowSizeMsg
      @viewport.set_width(msg.width)
      @textarea.set_width(msg.width)
      @viewport.set_height(msg.height - @textarea.height)

      if !@messages.empty?
        # Wrap content before setting it.
        content = Lipgloss::Style.new.width(@viewport.width).render(@messages.join("\n"))
        @viewport.set_content(content)
      end
      @viewport.goto_bottom
      {self, nil}
    when Tea::KeyPressMsg
      case msg.string
      when "ctrl+c", "esc"
        puts @textarea.value
        return {self, Tea.quit}
      when "enter"
        @messages << @sender_style.render("You: ") + @textarea.value
        content = Lipgloss::Style.new.width(@viewport.width).render(@messages.join("\n"))
        @viewport.set_content(content)
        @textarea.reset
        @viewport.goto_bottom
        return {self, nil}
      else
        ta, cmd = @textarea.update(msg)
        @textarea = ta
        return {self, cmd}
      end
    when Bubbles::Cursor::BlinkMsg
      ta, cmd = @textarea.update(msg)
      @textarea = ta
      return {self, cmd}
    else
      {self, nil}
    end
  end

  def view : Tea::View
    viewport_view = @viewport.view
    v = Tea.new_view(viewport_view + "\n" + @textarea.view)

    if c = @textarea.cursor
      c.y += Lipgloss.height(viewport_view)
      v.cursor = c
    end

    v.alt_screen = true
    v
  end
end

unless ENV["BUBBLETEA_EXAMPLE_DISABLE_MAIN"]? == "1"
  unless STDIN.tty? && STDOUT.tty?
    STDERR.puts "Error running program: bubbletea: error opening TTY: stdin/stdout are not TTY"
    exit 1
  end
  program = Tea::Program.new(ChatModel.new)
  _model, err = program.run
  if err
    STDERR.puts "Oof: #{err.message}"
    exit 1
  end
end
