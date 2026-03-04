require "../spec_helper"
require "../../lib/teatest/src/teatest"

ENV["BUBBLETEA_EXAMPLE_DISABLE_MAIN"] = "1"
require "../../examples/list_default"

describe "examples/list_default teatest" do
  it "renders title in the terminal output" do
    tm = Teatest.new_test_model(
      ListDefaultModel.new,
      [Teatest.with_initial_term_size(80, 24)]
    )

    Teatest.wait_for(
      tm.output,
      ->(buf : Bytes) { String.new(buf).includes?("My Fave Things") },
      [Teatest.with_duration(3.seconds)]
    )

    tm.send(Tea::QuitMsg.new)
    tm.wait_finished([Teatest.with_final_timeout(3.seconds)])
  end

  it "filters and quits with q after accepting filter" do
    tm = Teatest.new_test_model(
      ListDefaultModel.new,
      [Teatest.with_initial_term_size(80, 24)]
    )

    tm.send(Tea.key('/'))
    tm.type("linux")
    tm.send(Tea.key(Tea::KeyEnter))

    Teatest.wait_for(
      tm.output,
      ->(buf : Bytes) do
        output = String.new(buf)
        output.includes?("1 item") && output.includes?("Linux")
      end,
      [Teatest.with_duration(3.seconds)]
    )

    tm.send(Tea.key('q'))
    tm.wait_finished([Teatest.with_final_timeout(3.seconds)])
  end
end
