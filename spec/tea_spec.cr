require "spec"
require "../src/bubbletea"

# Test message types
struct CtxImplodeMsg
  include Tea::Msg
  property cancel_proc : Proc(Nil)

  def initialize(@cancel_proc : Proc(Nil))
  end
end

struct IncrementMsg
  include Tea::Msg
end

struct PanicMsg
  include Tea::Msg
end

struct ImmediateLoopMsg
  include Tea::Msg
end

# Test model for tea tests
class TestModel
  include Tea::Model

  property? executed = false
  property counter = 0
  property? panic_on_update = false

  def initialize
  end

  def init : Tea::Cmd?
    nil
  end

  def update(msg : Tea::Msg) : Tuple(Tea::Model, Tea::Cmd?)
    case msg
    when CtxImplodeMsg
      msg.cancel_proc.call
      sleep 100.milliseconds
    when IncrementMsg
      @counter += 1
    when Tea::KeyPressMsg
      case msg.to_s
      when "q", "ctrl+c"
        return {self, Tea.quit}
      end
    when PanicMsg
      raise "testing panic behavior"
    end

    {self, nil}
  end

  def view : Tea::View
    @executed = true
    Tea::View.new("success")
  end
end

class ImmediateLoopModel
  include Tea::Model

  def init : Tea::Cmd?
    immediate_cmd
  end

  def update(msg : Tea::Msg) : Tuple(Tea::Model, Tea::Cmd?)
    case msg
    when ImmediateLoopMsg
      {self, immediate_cmd}
    when Tea::KeyPressMsg
      return {self, Tea.quit} if msg.keystroke == "q"
      {self, nil}
    else
      {self, nil}
    end
  end

  def view : Tea::View
    Tea::View.new("looping")
  end

  private def immediate_cmd : Tea::Cmd
    -> do
      # Small delay to yield control and prevent tight loop
      # In Crystal, fibers need to yield; Go goroutines are preemptive
      sleep 1.millisecond
      ImmediateLoopMsg.new.as(Tea::Msg?)
    end
  end
end

class InitialWindowSizeModel
  include Tea::Model

  getter window_size_msg : Tea::WindowSizeMsg? = nil

  def init : Tea::Cmd?
    nil
  end

  def update(msg : Tea::Msg) : Tuple(Tea::Model, Tea::Cmd?)
    case msg
    when Tea::WindowSizeMsg
      @window_size_msg = msg
      {self, Tea.quit}
    else
      {self, nil}
    end
  end

  def view : Tea::View
    Tea::View.new("size-check")
  end
end

private def new_noninteractive_program(model : Tea::Model, ctx : Tea::ExecutionContext) : Tea::Program
  Tea.new_program(
    model,
    Tea.with_input(nil),
    Tea.with_output(IO::Memory.new),
    Tea.without_renderer,
    Tea.without_signals,
    Tea.with_context(ctx),
  )
end

describe "Tea" do
  describe "window size parity" do
    it "delivers initial WindowSizeMsg from with_window_size without tty" do
      model = InitialWindowSizeModel.new
      output = IO::Memory.new
      program = Tea.new_program(
        model,
        Tea.with_input(nil),
        Tea.with_output(output),
        Tea.with_window_size(80, 24),
        Tea.without_signals,
        Tea.without_renderer
      )

      _result, err = program.run
      err.should be_nil

      msg = model.window_size_msg
      msg.should_not be_nil
      msg.try &.width.should eq(80)
      msg.try &.height.should eq(24)
    end
  end

  describe "scheduler fairness" do
    it "processes quit input while immediate commands are looping" do
      model = ImmediateLoopModel.new
      output = IO::Memory.new
      program = Tea.new_program(
        model,
        Tea.with_input(IO::Memory.new("")),
        Tea.with_output(output),
        Tea.with_window_size(80, 24),
        Tea.without_signals,
      )

      done = Channel(Exception?).new(1)
      spawn do
        _result, err = program.run
        done.send(err)
      end

      spawn do
        sleep 25.milliseconds
        program.send(Tea.key('q'))
      end

      select
      when err = done.receive
        err.should be_nil
      when timeout(2.seconds)
        program.quit
        fail("program did not process quit under immediate command load")
      end
    end
  end

  describe "Model" do
    it "runs basic program" do
      buf = IO::Memory.new
      input = IO::Memory.new("q")

      ctx = Tea::ExecutionContext.new

      model = TestModel.new
      program = Tea.new_program(
        model,
        Tea.with_context(ctx),
        Tea.with_input(input),
        Tea.with_output(buf),
        Tea.without_signals,
      )

      _result, err = program.run

      err.should be_nil
      buf.size.should be > 0
    end

    it "quits on command" do
      buf = IO::Memory.new
      input = IO::Memory.new("")

      model = TestModel.new
      program = Tea.new_program(
        model,
        Tea.with_input(input),
        Tea.with_output(buf),
        Tea.without_signals,
      )

      # Start program in separate fiber
      spawn do
        # Wait for view to be executed
        until model.executed?
          Fiber.yield
        end
        program.quit
      end

      _result, err = program.run

      err.should be_nil
    end

    it "waits for quit" do
      buf = IO::Memory.new
      input = IO::Memory.new("")

      prog_started = Channel(Nil).new
      wait_started = Channel(Nil).new
      err_chan = Channel(Exception?).new(1)
      waiter_done = Channel(Nil).new(5)

      model = TestModel.new
      program = Tea.new_program(
        model,
        Tea.with_input(input),
        Tea.with_output(buf),
        Tea.without_signals,
      )

      # Start program
      spawn do
        _, err = program.run
        err_chan.send(err)
      end

      # Wait for program to start
      spawn do
        until model.executed?
          Fiber.yield
        end
        prog_started.send(nil)

        wait_started.receive
        sleep 50.milliseconds
        program.quit
      end

      prog_started.receive

      # Multiple waiters
      5.times do
        spawn do
          program.wait
          waiter_done.send(nil)
        end
      end

      wait_started.send(nil)
      5.times { waiter_done.receive }

      err = err_chan.receive
      err.should be_nil
    end

    it "waits for kill" do
      buf = IO::Memory.new
      input = IO::Memory.new("")

      prog_started = Channel(Nil).new
      wait_started = Channel(Nil).new
      err_chan = Channel(Exception?).new(1)
      waiter_done = Channel(Nil).new(5)

      model = TestModel.new
      program = Tea.new_program(
        model,
        Tea.with_input(input),
        Tea.with_output(buf),
        Tea.without_signals,
      )

      # Start program
      spawn do
        _, err = program.run
        err_chan.send(err)
      end

      # Wait for program to start then kill
      spawn do
        until model.executed?
          Fiber.yield
        end
        prog_started.send(nil)

        wait_started.receive
        sleep 50.milliseconds
        program.kill
      end

      prog_started.receive

      # Multiple waiters
      5.times do
        spawn do
          program.wait
          waiter_done.send(nil)
        end
      end

      wait_started.send(nil)
      5.times { waiter_done.receive }

      err = err_chan.receive
      err.should be_a(Tea::ProgramKilledError)
    end

    it "filters messages" do
      [0_u32, 1_u32, 2_u32].each do |prevent_count|
        buf = IO::Memory.new
        input = IO::Memory.new("")
        model = TestModel.new
        shutdowns = Atomic(UInt32).new(0_u32)

        program = Tea.new_program(
          model,
          Tea.with_input(input),
          Tea.with_output(buf),
          Tea.without_signals,
          Tea.with_filter do |_model, msg|
            if msg.is_a?(Tea::QuitMsg) && shutdowns.get < prevent_count
              shutdowns.add(1_u32)
              nil
            else
              msg
            end
          end
        )

        spawn do
          while shutdowns.get <= prevent_count
            sleep 1.millisecond
            program.quit
          end
        end

        _, err = program.run

        err.should be_nil
        shutdowns.get.should eq(prevent_count)
      end
    end

    it "handles context cancellation" do
      ctx = Tea::ExecutionContext.new

      model = TestModel.new
      program = new_noninteractive_program(model, ctx)

      spawn do
        until model.executed?
          Fiber.yield
        end
        ctx.cancel
      end

      _, err = program.run

      err.should be_a(Tea::ProgramKilledError)
    end

    it "handles context implosion without deadlock" do
      ctx = Tea::ExecutionContext.new

      model = TestModel.new
      program = new_noninteractive_program(model, ctx)

      spawn do
        until model.executed?
          Fiber.yield
        end
        program.send(CtxImplodeMsg.new(-> { ctx.cancel }))
      end

      _, err = program.run

      err.should be_a(Tea::ProgramKilledError)
    end

    it "handles batch message without deadlock" do
      ctx = Tea::ExecutionContext.new

      inc_cmd = -> {
        ctx.cancel
        IncrementMsg.new.as(Tea::Msg?)
      }

      model = TestModel.new
      program = new_noninteractive_program(model, ctx)

      spawn do
        until model.executed?
          Fiber.yield
        end
        batch = Tea::BatchMsg.new(Array(Tea::Cmd).new(100) { inc_cmd })
        program.send(batch)
      end

      _, err = program.run

      err.should be_a(Tea::ProgramKilledError)
    end

    it "handles batch messages" do
      buf = IO::Memory.new
      input = IO::Memory.new("")

      inc_cmd = -> { IncrementMsg.new.as(Tea::Msg?) }

      model = TestModel.new
      program = Tea.new_program(
        model,
        Tea.with_input(input),
        Tea.with_output(buf),
        Tea.without_signals,
      )

      spawn do
        batch = Tea::BatchMsg.new([inc_cmd, inc_cmd] of Tea::Cmd)
        program.send(batch)

        until model.counter >= 2
          sleep 1.millisecond
        end
        program.quit
      end

      _, err = program.run

      err.should be_nil
      model.counter.should eq 2
    end

    it "handles sequence messages" do
      buf = IO::Memory.new
      input = IO::Memory.new("")

      inc_cmd = -> { IncrementMsg.new.as(Tea::Msg?) }

      model = TestModel.new
      program = Tea.new_program(
        model,
        Tea.with_input(input),
        Tea.with_output(buf),
        Tea.without_signals,
      )

      spawn do
        seq = Tea::SequenceMsg.new([inc_cmd, inc_cmd, Tea.quit] of Tea::Cmd)
        program.send(seq)
      end

      _, err = program.run

      err.should be_nil
      model.counter.should eq 2
    end

    it "handles sequence with batch messages" do
      buf = IO::Memory.new
      input = IO::Memory.new("")

      inc_cmd = -> { IncrementMsg.new.as(Tea::Msg?) }
      batch_cmd = -> { Tea::BatchMsg.new([inc_cmd, inc_cmd] of Tea::Cmd).as(Tea::Msg?) }

      model = TestModel.new
      program = Tea.new_program(
        model,
        Tea.with_input(input),
        Tea.with_output(buf),
        Tea.without_signals,
      )

      spawn do
        seq = Tea::SequenceMsg.new([batch_cmd, inc_cmd, Tea.quit] of Tea::Cmd)
        program.send(seq)
      end

      _, err = program.run

      err.should be_nil
      model.counter.should eq 3
    end

    it "handles nested sequence messages" do
      buf = IO::Memory.new
      input = IO::Memory.new("")

      inc_cmd = -> { IncrementMsg.new.as(Tea::Msg?) }

      model = TestModel.new
      program = Tea.new_program(
        model,
        Tea.with_input(input),
        Tea.with_output(buf),
        Tea.without_signals,
      )

      spawn do
        seq = Tea::SequenceMsg.new([
          inc_cmd,
          -> { Tea.sequence([inc_cmd, inc_cmd, Tea.batch([inc_cmd, inc_cmd])]).not_nil!.call.as(Tea::Msg?) },
          Tea.quit,
        ] of Tea::Cmd)
        program.send(seq)
      end

      _, err = program.run

      err.should be_nil
      model.counter.should eq 5
    end

    it "sends messages" do
      model = TestModel.new
      program = Tea.new_program(
        model,
        Tea.with_input(IO::Memory.new("")),
        Tea.with_output(IO::Memory.new),
        Tea.without_signals,
      )

      # Sending before start is a blocking operation
      spawn do
        program.send(Tea::QuitMsg.new)
      end

      _, err = program.run

      err.should be_nil

      # Sending after quit is a no-op
      program.send(Tea::QuitMsg.new)
    end

    it "creates program without running" do
      buf = IO::Memory.new
      input = IO::Memory.new

      model = TestModel.new
      program = Tea::Program.new(model)

      # Just creating a program without running should not panic
      program.should be_a(Tea::Program)
    end

    it "handles panics" do
      model = TestModel.new
      program = Tea.new_program(
        model,
        Tea.with_input(IO::Memory.new("")),
        Tea.with_output(IO::Memory.new),
        Tea.without_signals,
      )

      spawn do
        until model.executed?
          Fiber.yield
        end
        program.send(PanicMsg.new)
      end

      _, err = program.run

      err.should be_a(Tea::ProgramKilledError)
      err.not_nil!.cause.should be_a(Tea::ProgramPanicError)
    end
  end
end
