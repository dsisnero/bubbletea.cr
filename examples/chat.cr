require "bubbles"
require "lipgloss"

class ChatModel
  include Tea::Model

  @viewport : Bubbles::Viewport::Model
  @input : String
  @messages : Array(String)
  @sender_style : Lipgloss::Style

  def initialize
    @viewport = Bubbles::Viewport.new(
      Bubbles::Viewport.with_width(30),
      Bubbles::Viewport.with_height(5)
    )
    @viewport.set_content("Welcome to the chat room!\nType a message and press Enter to send.")
    @viewport.key_map.left.set_enabled(false)
    @viewport.key_map.right.set_enabled(false)

    @input = ""
    @messages = [] of String
    @sender_style = Lipgloss::Style.new.foreground(Lipgloss.color("5"))
  end

  def init : Tea::Cmd?
    nil
  end

  def update(msg : Tea::Msg)
    case msg
    when Tea::WindowSizeMsg
      @viewport.set_width(msg.width)
      @viewport.set_height(msg.height - 3)

      if !@messages.empty?
        # Wrap content before setting it
        content = Lipgloss::Style.new.width(@viewport.width).render(@messages.join("\n"))
        @viewport.set_content(content)
      end
      @viewport.goto_bottom
      {self, nil}
    when Tea::KeyPressMsg
      case msg.string
      when "ctrl+c", "esc"
        puts @input
        return {self, Tea.quit}
      when "enter"
        @messages << @sender_style.render("You: ") + @input
        content = Lipgloss::Style.new.width(@viewport.width).render(@messages.join("\n"))
        @viewport.set_content(content)
        @input = ""
        @viewport.goto_bottom
        return {self, nil}
      when "backspace"
        @input = @input[0...-1] unless @input.empty?
        {self, nil}
      else
        # Handle printable characters
        if rune = msg.rune
          @input += rune.to_s
        elsif msg.type == Tea::KeyType::Space
          @input += " "
        end
        {self, nil}
      end
    else
      {self, nil}
    end
  end

  def view : Tea::View
    viewport_view = @viewport.view
    prompt = @input.empty? ? "Send a message..." : @input
    textarea_view = "┃ #{prompt}\n┃  \n┃  "

    v = Tea.new_view(viewport_view + "\n" + textarea_view)

    # Set cursor position
    v.cursor = Tea::Cursor.new(
      x: 2 + @input.size,
      y: Lipgloss.height(viewport_view),
      visible: true,
      style: Tea::CursorStyle::BlockBlinking,
      color: Colorful::Color.hex("#c0c0c0")
    )

    v.alt_screen = true
    v
  end
end

if PROGRAM_NAME == __FILE__
  program = Tea::Program.new(ChatModel.new)
  _model, err = program.run
  if err
    STDERR.puts "Oof: #{err.message}"
    exit 1
  end
end
