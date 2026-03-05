require "../spec_helper"

private class ResultParityModel
  include Bubbletea::Model

  CHOICES = ["Taro", "Coffee", "Lychee"]

  def initialize
    @cursor = 0
    @choice = ""
  end

  def init : Tea::Cmd?
    nil
  end

  def update(msg : Tea::Msg)
    case msg
    when Tea::KeyPressMsg
      case msg.string
      when "ctrl+c", "q", "esc"
        return {self, Tea.quit}
      when "enter"
        @choice = CHOICES[@cursor]
        return {self, Tea.quit}
      when "down", "j"
        @cursor += 1
        @cursor = 0 if @cursor >= CHOICES.size
      when "up", "k"
        @cursor -= 1
        @cursor = CHOICES.size - 1 if @cursor < 0
      end
    end
    {self, nil}
  end

  def view : Tea::View
    s = String::Builder.new
    s << "What kind of Bubble Tea would you like to order?\n\n"
    CHOICES.each_with_index do |choice, i|
      s << (@cursor == i ? "(•) " : "( ) ")
      s << choice << "\n"
    end
    s << "\n(press q to quit)\n"
    Tea::View.new(s.to_s)
  end
end

private def capture_result_output : Bytes
  output = IO::Memory.new
  program = Bubbletea.new_program(
    ResultParityModel.new,
    Tea.with_input(IO::Memory.new("")),
    Tea.with_output(output),
    Tea.without_signals,
    Tea.with_window_size(80, 24),
  )

  spawn do
    sleep 100.milliseconds
    program.send(Tea.key(Tea::KeyDown))
    sleep 40.milliseconds
    program.send(Tea.key(Tea::KeyEnter))
  end

  _model, err = program.run
  raise err.not_nil! if err
  output.to_slice
end

describe "examples/result parity" do
  it "matches the saved Go golden output exactly" do
    actual = capture_result_output
    expected = File.read("#{__DIR__}/golden/result.go.golden").to_slice
    actual.should eq(expected)
  end
end
