require "spec"
require "../src/bubbletea"

# Test message for exec completion
struct ExecFinishedMsg
  include Tea::Msg
  property error : Exception?

  def initialize(@error : Exception?)
  end
end

# Mock exec command for testing
class MockExecCommand
  include Tea::ExecCommand

  def run : Nil
    # Mock implementation
  end

  def set_stdin(reader : IO)
    # Mock implementation
  end

  def set_stdout(writer : IO)
    # Mock implementation
  end

  def set_stderr(writer : IO)
    # Mock implementation
  end
end

# Exec command that records assigned stdio and can optionally fail.
class InspectableExecCommand
  include Tea::ExecCommand

  getter stdin : IO? = nil
  getter stdout : IO? = nil
  getter stderr : IO? = nil

  def initialize(@failure : Exception? = nil)
  end

  def run : Nil
    @stdout.try &.puts("ok")
    raise @failure.not_nil! if @failure
  end

  def set_stdin(reader : IO)
    @stdin = reader
  end

  def set_stdout(writer : IO)
    @stdout = writer
  end

  def set_stderr(writer : IO)
    @stderr = writer
  end
end

# Test model for exec tests
class ExecTestModel
  include Tea::Model

  property command : String
  property args : Array(String)
  property error : Exception? = nil

  def initialize(@command : String, @args : Array(String) = [] of String)
  end

  def init : Tea::Cmd?
    callback = ->(err : Exception?) { ExecFinishedMsg.new(err).as(Tea::Msg?) }
    Tea.exec_process(@command, @args, callback)
  end

  def update(msg : Tea::Msg) : Tuple(Tea::Model, Tea::Cmd?)
    case msg
    when ExecFinishedMsg
      if msg.error
        @error = msg.error
      end
      return {self, Tea.quit}
    end

    {self, nil}
  end

  def view : Tea::View
    Tea::View.new("\n")
  end
end

class ExecCallbackModel
  include Tea::Model

  property error : Exception? = nil
  property completions : Int32 = 0

  def initialize(@cmd : Tea::Cmd)
  end

  def init : Tea::Cmd?
    @cmd
  end

  def update(msg : Tea::Msg) : Tuple(Tea::Model, Tea::Cmd?)
    case msg
    when ExecFinishedMsg
      @completions += 1
      @error = msg.error if msg.error
      {self, Tea.quit}
    else
      {self, nil}
    end
  end

  def view : Tea::View
    Tea::View.new("\n")
  end
end

private def new_exec_program(model : Tea::Model, output : IO = IO::Memory.new) : Tea::Program
  Tea.new_program(
    model,
    Tea.with_input(IO::Memory.new("")),
    Tea.with_output(output),
    Tea.without_signals,
  )
end

describe "Exec" do
  describe "Exec" do
    it "creates an exec command" do
      # Create a simple mock command that satisfies ExecCommand
      cmd = Tea.exec(MockExecCommand.new)
      cmd.should be_a(Tea::Cmd)

      msg = cmd.call
      msg.should be_a(Tea::ExecMsg)
    end
  end

  describe "ExecProcess" do
    it "creates a command from a command string" do
      cmd = Tea.exec_process("echo", ["hello"])
      cmd.should be_a(Tea::Cmd)
    end

    it "matches upstream process success and failure behavior" do
      tests = [
        {"invalid", true},
      ] of {String, Bool}

      {% unless flag?(:windows) %}
        tests << {"true", false}
        tests << {"false", true}
      {% end %}

      tests.each do |command, expect_error|
        model = ExecTestModel.new(command)
        program = new_exec_program(model)

        _, err = program.run

        err.should be_nil
        if expect_error
          model.error.should_not be_nil
        else
          model.error.should be_nil
        end
      end
    end

    it "passes stdio through to exec commands and delivers the callback message" do
      command = InspectableExecCommand.new
      model = ExecCallbackModel.new(
        Tea.exec(command, ->(err : Exception?) { ExecFinishedMsg.new(err).as(Tea::Msg?) })
      )
      output = IO::Memory.new
      program = new_exec_program(model, output)

      _, err = program.run

      err.should be_nil
      model.completions.should eq(1)
      model.error.should be_nil
      command.stdin.should_not be_nil
      command.stdout.should_not be_nil
      command.stderr.should_not be_nil
    end
  end

  describe "ExecShell" do
    it "creates a shell command" do
      cmd = Tea.exec_shell("echo test")
      cmd.should be_a(Tea::Cmd)
    end
  end

  describe "ExecCallback" do
    it "accepts a callback function" do
      callback = ->(err : Exception?) { nil.as(Tea::Msg?) }
      cmd = Tea.exec_process("echo", ["test"], callback)
      cmd.should be_a(Tea::Cmd)
    end
  end

  describe "Println" do
    it "creates a print command" do
      cmd = Tea.println("Hello", "World")
      cmd.should be_a(Tea::Cmd)

      msg = cmd.call
      msg.should be_a(Tea::PrintLineMsg)
      msg.as(Tea::PrintLineMsg).content.should eq "Hello World"
    end
  end

  describe "Printf" do
    it "creates a formatted print command" do
      cmd = Tea.printf("Hello %s", "World")
      cmd.should be_a(Tea::Cmd)

      msg = cmd.call
      msg.should be_a(Tea::PrintLineMsg)
      msg.as(Tea::PrintLineMsg).content.should eq "Hello World"
    end
  end

  describe "PrintLineMsg" do
    it "stores content" do
      msg = Tea::PrintLineMsg.new("test content")
      msg.content.should eq "test content"
    end
  end

  describe "ExecMsg" do
    it "stores command and callback" do
      cmd = MockExecCommand.new
      callback = ->(err : Exception?) { nil.as(Tea::Msg?) }

      msg = Tea::ExecMsg.new(cmd, callback)
      msg.cmd.should eq cmd
      msg.callback.should eq callback
    end
  end

  describe "External command integration" do
    it "sends completion message errors back to the model" do
      failure = Exception.new("boom")
      command = InspectableExecCommand.new(failure)
      model = ExecCallbackModel.new(
        Tea.exec(command, ->(err : Exception?) { ExecFinishedMsg.new(err).as(Tea::Msg?) })
      )

      _, err = new_exec_program(model).run

      err.should be_nil
      model.completions.should eq(1)
      model.error.should eq(failure)
    end

    it "runs shell commands on the current platform" do
      {% if flag?(:windows) %}
        model = ExecCallbackModel.new(
          Tea.exec_shell("echo test", ->(err : Exception?) { ExecFinishedMsg.new(err).as(Tea::Msg?) })
        )
        _, err = new_exec_program(model).run

        err.should be_nil
        model.completions.should eq(1)
        model.error.should be_nil
      {% else %}
        model = ExecCallbackModel.new(
          Tea.exec_shell("printf test >/dev/null", ->(err : Exception?) { ExecFinishedMsg.new(err).as(Tea::Msg?) })
        )
        _, err = new_exec_program(model).run

        err.should be_nil
        model.completions.should eq(1)
        model.error.should be_nil
      {% end %}
    end
  end
end
