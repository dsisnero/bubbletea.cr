require "../spec_helper"

ENV["BUBBLETEA_EXAMPLE_DISABLE_MAIN"] = "1"
require "../../examples/chat"

private def capture_chat_output : Bytes
  output = IO::Memory.new
  program = Bubbletea.new_program(
    ChatModel.new,
    Tea.with_input(IO::Memory.new("")),
    Tea.with_output(output),
    Tea.without_signals,
    Tea.with_window_size(80, 24),
  )

  spawn do
    sleep 120.milliseconds
    program.send(Tea.key('h'))
    sleep 30.milliseconds
    program.send(Tea.key('i'))
    sleep 30.milliseconds
    program.send(Tea.key(Tea::KeyEnter))
    sleep 60.milliseconds
    program.send(Tea.key(Tea::KeyEsc))
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
