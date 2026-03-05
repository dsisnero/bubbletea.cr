require "../spec_helper"

ENV["BUBBLETEA_EXAMPLE_DISABLE_MAIN"] = "1"
require "../../examples/chat"

private def capture_chat_output : Bytes
  output = IO::Memory.new
  program = Bubbletea.new_program(
    ChatModel.new,
    Tea.with_input(nil),
    Tea.with_output(output),
    Tea.without_signals,
    Tea.with_window_size(30, 8),
  )

  spawn do
    sleep 150.milliseconds
    program.send(Tea.key('h'))
    program.send(Tea.key('i'))
    program.send(Tea.key(Tea::KeyEnter))
    sleep 50.milliseconds
    program.send(Tea::QuitMsg.new)
  end

  _model, err = program.run
  raise err.not_nil! if err
  output.to_slice
end

describe "examples/chat parity" do
  golden = "#{__DIR__}/golden/chat.go.golden"

  if File.exists?(golden)
    it "matches the saved Go golden output exactly" do
      actual = capture_chat_output
      expected = File.read(golden).to_slice
      actual.should eq(expected)
    end
  else
    pending "matches the saved Go golden output exactly (missing fixture: #{golden})" do
    end
  end
end
