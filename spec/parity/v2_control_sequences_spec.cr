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
    # Derived from Go, not from this port. The program below was run against
    # the pinned Go sources (`vendor/bubbletea` f9df43c, v2.1.0) built with the
    # vendored `ultraviolet` (8ecbcf0) and its output captured byte for byte:
    # memory input/output, `WithoutSignalHandler`, `WithWindowSize(70, 30)`, a
    # one second tick and a quit at 1.2 s.
    #
    # Re-derive it the same way when either pin moves. The previous value was
    # captured from ultraviolet `524a660` (2026-02-05), where an inline frame
    # ended by moving to its last row and inline downward moves could be
    # remembered (`scrollHeight`). Upstream removed both in 2026-05, so Go has
    # emitted `<CR><ESC>[30C` at this boundary since then: the old bytes were
    # stale, not this port's.
    expected_b64 = "G1s/MjAyNiRwG1s/MjAyNyRwG1s/MjVsG1s/MjAwNGgbWz40OzJtG1s+MXUbWz91DRtbSkhpLiBUaGlzIHByb2dyYW0gd2lsbCBleGl0IGluIDEwIHNlY29uZHMuIFRvIHF1aXQgc29vbmVyIHByZXNzIGFueSBrZXkNG1szMEM5IHNlY29uZHMuIFRvIHF1aXQgc29vbmVyIHByZXNzIGFueSBrZXkuDRtbPjRtG1s8MXUKG1tKG1s/MjVoG1s/MjAwNGw="
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
      program.send(Tea.key(Tea::KeyEnter))
    end

    _model, err = program.run
    err.should be_nil

    actual = output.to_slice
    actual.should eq(expected)
  end
end
