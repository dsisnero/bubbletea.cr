require "../spec_helper"
require "base64"

struct V2ParityTickMsg
  include Tea::Msg
end

struct V2ParityModel
  include Bubbletea::Model

  def initialize(@value : Int32)
  end

  def init : Bubbletea::Cmd?
    -> : Tea::Msg? {
      sleep 1.second
      V2ParityTickMsg.new
    }
  end

  def update(msg : Tea::Msg)
    case msg
    when Tea::Key
      {self, Tea.quit}
    when V2ParityTickMsg
      @value -= 1
      if @value <= 0
        {self, Tea.quit}
      else
        {self, init}
      end
    else
      {self, nil}
    end
  end

  def view : Bubbletea::View
    Bubbletea::View.new("Hi. This program will exit in #{@value} seconds. To quit sooner press any key.\n")
  end
end

describe "v2 control sequence parity" do
  it "matches Go teatest v2 TestApp fixture bytes" do
    expected_b64 = "G1s/MjAyNiRwG1s/MjAyNyRwG1s/MjVsG1s/MjAwNGgbWz40OzJtG1s9MTsxdRtbP3UNG1tKSGkuIFRoaXMgcHJvZ3JhbSB3aWxsIGV4aXQgaW4gMTAgc2Vjb25kcy4gVG8gcXVpdCBzb29uZXIgcHJlc3MgYW55IGtleQ0KG1tBG1szMEM5IHNlY29uZHMuIFRvIHF1aXQgc29vbmVyIHByZXNzIGFueSBrZXkuDRtbPjRtG1s9MDsxdQobW0obWz8yNWgbWz8yMDA0bA=="
    expected = Base64.decode(expected_b64)

    input = IO::Memory.new
    output = IO::Memory.new

    program = Bubbletea.new_program(
      V2ParityModel.new(10),
      Tea.with_input(input),
      Tea.with_output(output),
      Tea.without_signals,
      Tea.with_window_size(70, 30),
    )

    spawn do
      sleep 1.2.seconds
      program.send(Tea.wrap("ignored msg"))
      program.send(Tea.key(Tea::KeyType::Enter))
    end

    _model, err = program.run
    err.should be_nil

    actual = output.to_slice
    actual.should eq(expected)
  end
end
