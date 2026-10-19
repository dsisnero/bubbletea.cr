require "spec"
require "base64"
require "../src/bubbletea"

private def program_status_set(status : Tea::ProgramStatus) : String
  Tea::ProgramStatusProtocol.set(status)
end

private def assert_status_in_order(got : String, *wants : String) : Nil
  rest = got
  wants.each do |want|
    idx = rest.index(want)
    raise "expected #{want.inspect} to appear after the previous sequences in #{got.inspect}" unless idx
    rest = rest[(idx + want.size)..]
  end
end

describe "Program Status Protocol" do
  it "encodes the documented states and fields" do
    set = ->(status : Tea::ProgramStatus) { program_status_set(status) }

    set.call(Tea::ProgramStatus.new(state: Tea::ProgramState::Working))
      .should eq "\e]7501;state=working\a"

    set.call(Tea::ProgramStatus.new(
      state: Tea::ProgramState::Blocked,
      kind: Tea::ProgramStatusKind::Permission,
      app: "terraform",
      message: "Apply 3 to add, 1 to change, 0 to destroy?",
    )).should eq(
      "\e]7501;state=blocked:kind=permission:app=terraform:" \
      "msg=#{Base64.strict_encode("Apply 3 to add, 1 to change, 0 to destroy?")}\a"
    )

    set.call(Tea::ProgramStatus.new(
      state: Tea::ProgramState::Working,
      id: "us-east",
      title: "US East",
      progress: 40,
      has_progress: true,
      message: "Pushing image",
    )).should eq(
      "\e]7501;state=working:id=us-east:progress=40:" \
      "title=#{Base64.strict_encode("US East")}:msg=#{Base64.strict_encode("Pushing image")}\a"
    )

    set.call(Tea::ProgramStatus.new(
      state: Tea::ProgramState::Blocked,
      progress: 300,
      has_progress: true,
    )).should eq "\e]7501;state=blocked:progress=100\a"
  end

  it "omits fields that do not apply or are invalid" do
    set = ->(status : Tea::ProgramStatus) { program_status_set(status) }

    set.call(Tea::ProgramStatus.new(state: Tea::ProgramState::Done, progress: 50, has_progress: true))
      .should eq "\e]7501;state=done\a"
    set.call(Tea::ProgramStatus.new(state: Tea::ProgramState::Working, kind: Tea::ProgramStatusKind::Auth))
      .should eq "\e]7501;state=working\a"
    set.call(Tea::ProgramStatus.new(state: Tea::ProgramState::Idle, app: "my app"))
      .should eq "\e]7501;state=idle\a"
    set.call(Tea::ProgramStatus.new(state: Tea::ProgramState::Error, message: "a\n\nb"))
      .should eq "\e]7501;state=error:msg=#{Base64.strict_encode("a b")}\a"
    set.call(Tea::ProgramStatus.new(state: Tea::ProgramState::Clear, app: "x", message: "y"))
      .should eq Tea::ProgramStatusProtocol::CLEAR
  end

  it "rejects invalid record ids" do
    {"a b", "a//b", "a/b/c/d/e/f/g/h/i", "a" * 33}.each do |id|
      program_status_set(Tea::ProgramStatus.new(state: Tea::ProgramState::Idle, id: id)).should eq ""
    end

    program_status_set(Tea::ProgramStatus.new(state: Tea::ProgramState::Idle, id: "build/test"))
      .should eq "\e]7501;state=idle:id=build/test\a"
  end

  it "clears a record by id" do
    Tea::ProgramStatusProtocol.clear_id("eu-west").should eq "\e]7501;state=clear:id=eu-west\a"
    Tea::ProgramStatusProtocol.clear_id("bad id").should eq ""
    Tea::ProgramStatusProtocol::REQUEST_SUPPORT.should eq "\e]7501;?\a"
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
      state: Tea::ProgramState::Working,
      app: "tea",
      message: "Building",
    )

    view = Tea::View.new("hello")
    view.program_status = working
    renderer.render(view)
    renderer.flush(false).should be_nil
    output.to_s.should contain(Tea::ProgramStatusProtocol.set(working))

    # Unchanged status is not written again.
    output.clear
    renderer.render(view)
    renderer.flush(false).should be_nil
    output.to_s.should_not contain("7501")

    # Changed message is written.
    changed = Tea::ProgramStatus.new(
      state: Tea::ProgramState::Working,
      app: "tea",
      message: "Linking",
    )
    output.clear
    changed_view = Tea::View.new("hello")
    changed_view.program_status = changed
    renderer.render(changed_view)
    renderer.flush(false).should be_nil
    output.to_s.should contain(Tea::ProgramStatusProtocol.set(changed))

    # Switching to a child record clears the root and sets the child.
    child = Tea::ProgramStatus.new(
      state: Tea::ProgramState::Blocked,
      id: "job",
      kind: Tea::ProgramStatusKind::Question,
    )
    output.clear
    child_view = Tea::View.new("hello")
    child_view.program_status = child
    renderer.render(child_view)
    renderer.flush(false).should be_nil
    got = output.to_s
    got.should_not contain(Tea::ProgramStatusProtocol.clear_id("job"))
    assert_status_in_order(got,
      "\e]7501;state=clear\a",
      Tea::ProgramStatusProtocol.set(child)
    )

    # Removing the status clears the child record.
    output.clear
    renderer.render(Tea::View.new("hello"))
    renderer.flush(false).should be_nil
    output.to_s.should contain(Tea::ProgramStatusProtocol.clear_id("job"))

    # Invalid ids are not written.
    output.clear
    invalid = Tea::ProgramStatus.new(state: Tea::ProgramState::Idle, id: "bad id")
    invalid_view = Tea::View.new("hello")
    invalid_view.program_status = invalid
    renderer.render(invalid_view)
    renderer.flush(false).should be_nil
    output.to_s.should_not contain("7501")

    # Done status stays in place on close.
    done = Tea::ProgramStatus.new(state: Tea::ProgramState::Done, app: "tea")
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
    output.to_s.should contain(Tea::ProgramStatusProtocol.set(done))
  end
end

describe "program status support" do
  it "translates an OSC 7501 reply into ProgramStatusSupportMsg" do
    # Port of Go test TestTranslateProgramStatusSupport.
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
