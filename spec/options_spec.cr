require "spec"
require "../src/bubbletea"

describe "Options" do
  describe "output" do
    it "sets custom output" do
      buf = IO::Memory.new
      opt = Tea::Options.with_output(buf)
      opt.should be_a(Tea::ProgramOption)

      program = Tea::Program.new
      opt.call(program)
      program.output.should eq(buf)
    end
  end

  describe "renderer" do
    it "disables renderer" do
      opt = Tea::Options.without_renderer
      opt.should be_a(Tea::ProgramOption)

      program = Tea::Program.new
      opt.call(program)
      program.disable_renderer?.should be_true
    end
  end

  describe "without signals" do
    it "ignores signals" do
      opt = Tea.without_signals
      opt.should be_a(Tea::ProgramOption)

      program = Tea::Program.new
      opt.call(program)
      program.ignore_signals?.should be_true
    end
  end

  describe "filter" do
    it "sets filter function" do
      filter_fn = ->(_model : Tea::Model, msg : Tea::Msg) { msg.as(Tea::Msg?) }
      opt = Tea::Options.with_filter(&filter_fn)
      opt.should be_a(Tea::ProgramOption)

      program = Tea::Program.new
      opt.call(program)
      program.filter.should_not be_nil
    end
  end

  describe "external context" do
    it "sets external context" do
      ctx = Tea::ExecutionContext.new
      opt = Tea::Options.with_context(ctx)
      opt.should be_a(Tea::ProgramOption)
    end
  end

  describe "input options" do
    it "handles nil input" do
      opt = Tea::Options.with_input(nil)
      opt.should be_a(Tea::ProgramOption)

      program = Tea::Program.new
      opt.call(program)
      program.disable_input?.should be_true
      program.input.should be_nil
    end

    it "handles custom input" do
      buf = IO::Memory.new
      opt = Tea::Options.with_input(buf)
      opt.should be_a(Tea::ProgramOption)

      program = Tea::Program.new
      opt.call(program)
      program.input.should eq(buf)
      program.disable_input?.should be_false
    end
  end

  describe "startup options" do
    it "without catch panics" do
      opt = Tea.without_catch_panics
      opt.should be_a(Tea::ProgramOption)

      program = Tea::Program.new
      opt.call(program)
      program.disable_catch_panics?.should be_true
    end

    it "without signal handler" do
      opt = Tea.without_signal_handler
      opt.should be_a(Tea::ProgramOption)

      program = Tea::Program.new
      opt.call(program)
      program.disable_signal_handler?.should be_true
    end
  end

  describe "environment" do
    it "sets environment variables" do
      env = Ultraviolet::Environ.new(["TERM=xterm-256color", "HOME=/home/user"])
      opt = Tea.with_environment(env)
      opt.should be_a(Tea::ProgramOption)

      program = Tea::Program.new
      opt.call(program)
      program.env.should eq(env)
    end
  end

  describe "color profile" do
    it "sets color profile" do
      opt = Tea.with_color_profile(Ultraviolet::ColorProfile::ANSI256)
      opt.should be_a(Tea::ProgramOption)

      program = Tea::Program.new
      opt.call(program)
      program.profile.should eq(Ultraviolet::ColorProfile::ANSI256)
    end
  end

  describe "window size" do
    it "sets window size" do
      opt = Tea.with_window_size(80, 24)
      opt.should be_a(Tea::ProgramOption)

      program = Tea::Program.new
      opt.call(program)
      program.width.should eq(80)
      program.height.should eq(24)
    end
  end

  describe "convenience methods" do
    it "provides with_context" do
      ctx = Tea::ExecutionContext.new
      opt = Tea.with_context(ctx)
      opt.should be_a(Tea::ProgramOption)
    end

    it "provides without_input" do
      opt = Tea.without_input
      opt.should be_a(Tea::ProgramOption)

      program = Tea::Program.new
      opt.call(program)
      program.disable_input?.should be_true
    end

    it "provides without_renderer" do
      opt = Tea.without_renderer
      opt.should be_a(Tea::ProgramOption)
    end

    it "provides with_fps" do
      opt = Tea.with_fps(30)
      opt.should be_a(Tea::ProgramOption)

      program = Tea::Program.new
      opt.call(program)
      program.fps.should eq(30)
    end

    it "clamps fps to valid range" do
      opt = Tea.with_fps(200)
      program = Tea::Program.new
      opt.call(program)
      program.fps.should eq(120)

      opt = Tea.with_fps(0)
      opt.call(program)
      program.fps.should eq(1)
    end

    it "provides with_filter" do
      opt = Tea.with_filter { |_, msg| msg }
      opt.should be_a(Tea::ProgramOption)
    end

    it "provides with_alt_screen" do
      opt = Tea.with_alt_screen
      opt.should be_a(Tea::ProgramOption)
    end

    it "provides with_mouse_cell_motion" do
      opt = Tea.with_mouse_cell_motion
      opt.should be_a(Tea::ProgramOption)
    end

    it "provides with_mouse_all_motion" do
      opt = Tea.with_mouse_all_motion
      opt.should be_a(Tea::ProgramOption)
    end

    it "provides with_report_focus" do
      opt = Tea.with_report_focus
      opt.should be_a(Tea::ProgramOption)
    end
  end
end
