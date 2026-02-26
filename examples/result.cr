# Result Example - Menu Selection
# Ported from Go: vendor/examples/result/main.go
# A simple example showing how to retrieve a value after the program exits.

require "../src/bubbletea"

# Menu choices
CHOICES = ["Taro", "Coffee", "Lychee"]

# Model holds the application state
struct Model
  include Tea::Model

  property cursor : Int32 = 0
  property choice : String = ""

  def initialize
  end

  # Initialize the model - no commands needed
  def init : Tea::Cmd?
    nil
  end

  # Update handles messages and updates the model
  def update(msg : Tea::Msg)
    case msg
    when Tea::KeyPressMsg
      case msg.to_s
      when "ctrl+c", "q", "esc"
        return {self.as(Tea::Model), Tea.quit}
      when "enter"
        # Save choice and quit
        @choice = CHOICES[@cursor]
        return {self.as(Tea::Model), Tea.quit}
      when "down", "j"
        @cursor += 1
        @cursor = 0 if @cursor >= CHOICES.size
      when "up", "k"
        @cursor -= 1
        @cursor = CHOICES.size - 1 if @cursor < 0
      end
    end

    {self.as(Tea::Model), nil}
  end

  # View renders the current state
  def view : Tea::View
    lines = [] of String
    lines << "What kind of Bubble Tea would you like to order?"
    lines << ""

    CHOICES.each_with_index do |choice, i|
      if @cursor == i
        lines << "(•) #{choice}"
      else
        lines << "( ) #{choice}"
      end
    end

    lines << ""
    lines << "(press q to quit)"

    Tea::View.new(lines.join("\n"))
  end
end

# Main entry point
model = Model.new
program = Tea::Program.new(model)

# Run returns the final model
final_model, err = program.run

if err
  puts "Oh no: #{err}"
  exit 1
end

# Access the choice from the final model
if final_model.is_a?(Model) && !final_model.choice.empty?
  puts "\n---"
  puts "You chose #{final_model.choice}!"
end