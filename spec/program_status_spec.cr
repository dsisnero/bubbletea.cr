require "spec"
require "../src/bubbletea"

private def assert_status_in_order(got : String, *wants : String) : Nil
  rest = got
  wants.each do |want|
    idx = rest.index(want)
    raise "expected #{want.inspect} to appear after the previous sequences in #{got.inspect}" unless idx
    rest = rest[(idx + want.size)..]
  end
end

describe "Program Status Protocol" do
  it "aliases the ansi shard types and constants" do
    status = Tea::ProgramStatus.new(
      state: Tea::ProgramStateWorking,
      kind: Tea::ProgramStatusKindQuestion,
      has_progress: true,
      progress: 40,
    )

    status.should be_a(Ansi::ProgramStatus)
    status.state.should eq Ansi::ProgramState::Working
    status.kind.should eq Ansi::ProgramStatusKind::Question
    status.has_progress?.should be_true
  end
end

describe Tea::CursedRenderer do
  it "reports program status and leaves it in place on close" do
    # Port of Go test TestCursedRenderer_programStatus.
    output = IO::Memory.new
    renderer = Tea::CursedRenderer.new(
      output,
      Ultraviolet::Environ.new(["TERM=xterm-256color"]),
      80,
      24,
    )
    renderer.start

    working = Tea::ProgramStatus.new(
      state: Tea::ProgramStateWorking,
      app: "tea",
      message: "Building",
    )

    view = Tea::View.new("hello")
    view.program_status = working
    renderer.render(view)
    renderer.flush(false).should be_nil
    output.to_s.should contain(Ansi.set_program_status(working))

    # Unchanged status is not written again.
    output.clear
    renderer.render(view)
    renderer.flush(false).should be_nil
    output.to_s.should_not contain("7501")

    # Changed message is written.
    changed = Tea::ProgramStatus.new(
      state: Tea::ProgramStateWorking,
      app: "tea",
      message: "Linking",
    )
    changed_view = Tea::View.new("hello")
    changed_view.program_status = changed
    output.clear
    renderer.render(changed_view)
    renderer.flush(false).should be_nil
    output.to_s.should contain(Ansi.set_program_status(changed))

    # Switching to a child record clears the root and sets the child.
    child = Tea::ProgramStatus.new(
      state: Tea::ProgramStateBlocked,
      id: "job",
      kind: Tea::ProgramStatusKindQuestion,
    )
    child_view = Tea::View.new("hello")
    child_view.program_status = child
    output.clear
    renderer.render(child_view)
    renderer.flush(false).should be_nil
    got = output.to_s
    got.should_not contain(Ansi.clear_program_status_id("job"))
    assert_status_in_order(got,
      Ansi::ClearProgramStatus,
      Ansi.set_program_status(child)
    )

    # Removing the status clears the child record.
    output.clear
    renderer.render(Tea::View.new("hello"))
    renderer.flush(false).should be_nil
    output.to_s.should contain(Ansi.clear_program_status_id("job"))

    # Invalid ids are not written.
    output.clear
    invalid_view = Tea::View.new("hello")
    invalid_view.program_status = Tea::ProgramStatus.new(
      state: Tea::ProgramStateIdle,
      id: "bad id",
    )
    renderer.render(invalid_view)
    renderer.flush(false).should be_nil
    output.to_s.should_not contain("7501")

    # Done status stays in place on close.
    done = Tea::ProgramStatus.new(state: Tea::ProgramStateDone, app: "tea")
    done_view = Tea::View.new("hello")
    done_view.program_status = done
    renderer.render(done_view)
    renderer.flush(false).should be_nil
    output.clear
    renderer.close.should be_nil
    output.to_s.should_not contain("7501")

    # Resuming re-sends the last status.
    output.clear
    renderer.start
    renderer.flush(false).should be_nil
    output.to_s.should contain(Ansi.set_program_status(done))
  end
end

describe "program status support" do
  it "translates an OSC 7501 reply into ProgramStatusSupportMsg" do
    # Port of Go test TestTranslateProgramStatusSupport. The ultraviolet
    # decoder still emits UnknownOscEvent, so the shim recognises the reply.
    program = Tea::Program.new
    msg = program.translate_input_event(Ultraviolet::UnknownOscEvent.new("\e]7501;?\a"))

    msg.should be_a(Tea::ProgramStatusSupportMsg)
  end

  it "leaves other unknown OSC sequences untouched" do
    program = Tea::Program.new
    event = Ultraviolet::UnknownOscEvent.new("\e]9999;?\a")
    msg = program.translate_input_event(event)

    msg.should_not be_a(Tea::ProgramStatusSupportMsg)
  end
end
