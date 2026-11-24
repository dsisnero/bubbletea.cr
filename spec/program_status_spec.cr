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

private class ProgramStatusRequestModel
  include Tea::Model

  def init : Tea::Cmd?
    Tea.request_program_status_support
  end

  def update(msg : Tea::Msg) : Tuple(Tea::Model, Tea::Cmd?)
    return {self, Tea.quit} if msg.is_a?(Tea::RequestProgramStatusSupportMsg)

    {self, nil}
  end

  def view : Tea::View
    Tea::View.new("")
  end
end

private class ProgramStatusReplyModel
  include Tea::Model

  getter replies = 0

  def init : Tea::Cmd?
    nil
  end

  def update(msg : Tea::Msg) : Tuple(Tea::Model, Tea::Cmd?)
    if msg.is_a?(Tea::ProgramStatusSupportMsg)
      @replies += 1
      return {self, Tea.quit}
    end

    {self, nil}
  end

  def view : Tea::View
    Tea::View.new("")
  end
end

private def run_program_status_program(model : Tea::Model, output : IO::Memory, &)
  program = Tea.new_program(
    model,
    Tea.with_input(IO::Memory.new),
    Tea.with_output(output),
    Tea.without_signals,
  )
  yield program
  program.run
end

describe "program status support" do
  it "translates a program status support reply" do
    # Port of Go test TestTranslateProgramStatusSupport.
    program = Tea::Program.new
    msg = program.translate_input_event(Ultraviolet::ProgramStatusSupportEvent.new)

    msg.should be_a(Tea::ProgramStatusSupportMsg)
  end

  it "leaves other unknown OSC sequences untouched" do
    # Go's translateInputEvent has no UnknownOscEvent case, so an OSC 7501-
    # shaped sequence that ultraviolet did not decode as a support reply is
    # passed through untouched.
    program = Tea::Program.new
    event = Ultraviolet::UnknownOscEvent.new("\e]9999;?\a")
    msg = program.translate_input_event(event)

    msg.should_not be_a(Tea::ProgramStatusSupportMsg)
  end

  it "writes the OSC 7501 query when the model asks for support" do
    output = IO::Memory.new
    _model, err = run_program_status_program(ProgramStatusRequestModel.new, output) { }
    err.should be_nil

    output.to_s.should contain(Ansi::RequestProgramStatusSupport)
  end

  it "hands the reply to the model without re-querying the terminal" do
    # Go keeps the request (unexported programStatusSupportMsg) and the
    # terminal's reply (ProgramStatusSupportMsg) as distinct messages, so a
    # reply is a user-visible event and never re-triggers the query.
    output = IO::Memory.new
    final, err = run_program_status_program(ProgramStatusReplyModel.new, output) do |program|
      spawn do
        sleep 300.milliseconds
        program.send(program.translate_input_event(Ultraviolet::ProgramStatusSupportEvent.new))
      end
    end
    err.should be_nil

    final.as(ProgramStatusReplyModel).replies.should eq 1
    output.to_s.should_not contain(Ansi::RequestProgramStatusSupport)
  end
end
