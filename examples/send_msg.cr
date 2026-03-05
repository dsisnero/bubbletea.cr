require "../src/bubbletea"
require "bubbles"
require "lipgloss"

SEND_MSG_SPINNER_STYLE = Lipgloss::Style.new.foreground(Lipgloss.color("63"))
SEND_MSG_HELP_STYLE = Lipgloss::Style.new.foreground(Lipgloss.color("241")).margin(1, 0)
SEND_MSG_DOT_STYLE = begin
  s = SEND_MSG_HELP_STYLE.dup
  s.unset_margins
  s
end
SEND_MSG_DURATION_STYLE = SEND_MSG_DOT_STYLE
SEND_MSG_APP_STYLE = Lipgloss::Style.new.margin(1, 2, 0, 2)

class SendMsgResult
  include Tea::Msg

  getter duration : Time::Span
  getter food : String

  def initialize(@duration : Time::Span, @food : String)
  end

  def to_s : String
    if @duration.zero?
      return SEND_MSG_DOT_STYLE.render("." * 30)
    end

    "🍔 Ate #{@food} #{SEND_MSG_DURATION_STYLE.render(duration_string(@duration))}"
  end

  private def duration_string(duration : Time::Span) : String
    "#{duration.total_milliseconds.round.to_i}ms"
  end
end

class SendMsgModel
  include Bubbletea::Model

  @spinner : Bubbles::Spinner::Model
  @results : Array(SendMsgResult)
  @quitting : Bool

  def initialize
    @spinner = Bubbles::Spinner.new
    @spinner.style = SEND_MSG_SPINNER_STYLE
    @results = Array.new(5) { SendMsgResult.new(0.milliseconds, "") }
    @quitting = false
  end

  def init : Bubbletea::Cmd?
    -> { @spinner.tick.as(Tea::Msg?) }
  end

  def update(msg : Tea::Msg)
    case msg
    when Bubbletea::KeyPressMsg
      @quitting = true
      {self, Bubbletea.quit}
    when SendMsgResult
      @results = @results[1..] + [msg]
      {self, nil}
    when Bubbles::Spinner::TickMsg
      @spinner, cmd = @spinner.update(msg)
      {self, cmd}
    else
      {self, nil}
    end
  end

  def view : Bubbletea::View
    b = String.build do |io|
      if @quitting
        io << "That's all for today!"
      else
        io << @spinner.view
        io << " Eating food..."
      end
      io << "\n\n"

      @results.each do |result|
        io << result.to_s
        io << '\n'
      end

      io << SEND_MSG_HELP_STYLE.render("Press any key to exit") unless @quitting
      io << '\n' if @quitting
    end

    Bubbletea::View.new(SEND_MSG_APP_STYLE.render(b))
  end
end

private def random_food : String
  foods = [
    "an apple", "a pear", "a gherkin", "a party gherkin",
    "a kohlrabi", "some spaghetti", "tacos", "a currywurst", "some curry",
    "a sandwich", "some peanut butter", "some cashews", "some ramen",
  ]
  foods.sample || "food"
end

unless ENV["BUBBLETEA_EXAMPLE_DISABLE_MAIN"]? == "1"
  program = Bubbletea::Program.new(SendMsgModel.new)

  # Simulate activity.
  spawn do
    loop do
      pause = (Random.rand(899) + 100).milliseconds
      sleep pause
      program.send(SendMsgResult.new(pause, random_food))
    end
  end

  _model, err = program.run
  if err
    STDERR.puts "Error running program: #{err.message}"
    exit 1
  end
end
