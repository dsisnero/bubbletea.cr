require "../src/bubbletea"

class ChatModel
  include Bubbletea::Model

  def initialize
    @width = 30
    @height = 8
    @messages = [] of String
    @input = ""
  end

  def init : Bubbletea::Cmd?
    Bubbletea.tick(500.milliseconds, ->(_time : Time) { Bubbletea["blink"].as(Tea::Msg?) })
  end

  def update(msg : Tea::Msg)
    case msg
    when Bubbletea::WindowSizeMsg
      @width = msg.width
      @height = msg.height
      {self, nil}
    when Bubbletea::KeyPressMsg
      case msg.string_with_mods
      when "ctrl+c", "esc"
        {self, Bubbletea.quit}
      when "enter"
        @messages << "You: #{@input}"
        @input = ""
        {self, nil}
      when "backspace"
        @input = @input[0...-1] unless @input.empty?
        {self, nil}
      when "space"
        @input += " "
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
    header = "Welcome to the chat room!\nType a message and press Enter to send."

    text_body = if @messages.empty?
                  header
                else
                  @messages.join("\n")
                end

    viewport_height = {@height - 3, 3}.max
    lines = text_body.split('\n')
    visible = lines.last(viewport_height).join("\n")

    content = String.build do |io|
      io << visible
      io << "\n"
      io << "┃ "
      io << @input
    end

    v = Bubbletea::View.new(content)
    v.alt_screen = true
    v
  end
end

program = Bubbletea::Program.new(ChatModel.new)
_model, err = program.run
if err
  STDERR.puts "Oof: #{err.message}"
  exit 1
end
