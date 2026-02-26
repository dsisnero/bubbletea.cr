require "../src/bubbletea"

class KeyboardEnhancementsModel
  include Bubbletea::Model

  def initialize
    @supports_disambiguation = false
    @supports_event_types = false
  end

  def init : Bubbletea::Cmd?
    Tea.request_background_color
  end

  def update(msg : Tea::Msg)
    case msg
    when Bubbletea::KeyboardEnhancementsMsg
      @supports_disambiguation = true
      @supports_event_types = msg.supports_event_types?
      {self, nil}
    when Bubbletea::KeyPressMsg
      case msg.string_with_mods
      when "ctrl+c"
        {self, Bubbletea.quit}
      else
        {self, Bubbletea.println("  press: #{msg.string_with_mods}")}
      end
    when Bubbletea::KeyReleaseMsg
      {self, Bubbletea.printf("release: %s", msg.to_s)}
    when Tea::BackgroundColorMsg
      {self, nil}
    else
      {self, nil}
    end
  end

  def view : Bubbletea::View
    text = String.build do |io|
      io << "Terminal supports key releases: #{@supports_event_types}\n"
      io << "Terminal supports key disambiguation: #{@supports_disambiguation}\n"
      io << "This demo logs key events. Press ctrl+c to quit.\n"
    end

    v = Bubbletea::View.new(text)
    v.keyboard_enhancements.report_event_types = true
    v
  end
end

program = Bubbletea::Program.new(KeyboardEnhancementsModel.new)
_model, err = program.run
if err
  STDERR.puts "Urgh: #{err.message}"
  exit 1
end
