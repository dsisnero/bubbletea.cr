require "../src/bubbletea"
require "lipgloss"

struct KeyboardEnhancementStyles
  property ui : Lipgloss::Style

  def initialize
    @ui = Lipgloss::Style.new
  end
end

class KeyboardEnhancementsModel
  include Bubbletea::Model

  @supports_disambiguation : Bool
  @supports_event_types : Bool
  @styles : KeyboardEnhancementStyles

  def initialize
    @supports_disambiguation = false
    @supports_event_types = false
    @styles = KeyboardEnhancementStyles.new
    update_styles(true)
  end

  def self.initial_model : self
    new
  end

  def init : Bubbletea::Cmd?
    Tea.request_background_color
  end

  def update(msg : Tea::Msg)
    case msg
    when Tea::KeyboardEnhancementsMsg
      @supports_disambiguation = true
      @supports_event_types = msg.supports_event_types?
    when Tea::KeyPressMsg
      case msg.keystroke
      when "ctrl+c"
        return {self, Tea.quit}
      else
        return {self, Tea.println("  press: " + msg.string)}
      end
    when Tea::KeyReleaseMsg
      return {self, Tea.printf("release: %s", msg.string)}
    when Tea::BackgroundColorMsg
      update_styles(msg.is_dark?)
    end
    {self, nil}
  end

  def view : Bubbletea::View
    content = String.build do |b|
      b << "Terminal supports key releases: " << @supports_event_types << '\n'
      b << "Terminal supports key disambiguation: " << @supports_disambiguation << '\n'
      b << "This demo logs key events. Press ctrl+c to quit."
    end

    v = Tea.new_view(content + "\n")
    v.keyboard_enhancements.report_event_types = true
    v
  end

  private def update_styles(is_dark : Bool)
    light = is_dark ? Lipgloss.color("239") : Lipgloss.color("245")
    dark = is_dark ? Lipgloss.color("245") : Lipgloss.color("239")
    @styles.ui = Lipgloss::Style.new
      .foreground(light)
      .border(Lipgloss::Border.normal, true, false, false, false)
      .border_foreground(dark)
  end
end

unless ENV["BUBBLETEA_EXAMPLE_DISABLE_MAIN"]? == "1"
  unless STDIN.tty? && STDOUT.tty?
    STDERR.puts "Error running program: bubbletea: error opening TTY: stdin/stdout are not TTY"
    exit 1
  end
  p = Tea::Program.new(KeyboardEnhancementsModel.initial_model)
  _m, err = p.run
  if err
    STDERR.puts "Urgh: #{err.message}"
    exit 1
  end
end
