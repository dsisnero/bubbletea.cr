# Program options for Tea v2-exp
# Ported from Go options.go

module Tea
  # Program options
  module Options
    # WithContext sets the context for the program
    def self.with_context(ctx : ExecutionContext) : ProgramOption
      ->(program : Program) do
        # Context is passed directly to run method, not stored
        # This is a no-op for compatibility
      end
    end

    # WithOutput sets the output writer (default: STDOUT)
    def self.with_output(output : IO) : ProgramOption
      ->(program : Program) do
        program.output = output
      end
    end

    # WithInput sets the input reader (default: STDIN)
    # Pass nil to disable input entirely
    def self.with_input(input : IO?) : ProgramOption
      ->(program : Program) do
        program.input = input
        program.disable_input = input.nil?
      end
    end

    # WithEnvironment sets the environment variables for the program.
    # This is useful when running in remote sessions (e.g. SSH).
    def self.with_environment(env : Ultraviolet::Environ) : ProgramOption
      ->(program : Program) do
        program.env = env
      end
    end

    # WithoutSignalHandler disables the signal handler.
    # Useful if you want to handle signals yourself.
    def self.without_signal_handler : ProgramOption
      ->(program : Program) do
        program.disable_signal_handler = true
      end
    end

    # WithoutCatchPanics disables panic catching.
    # If disabled, the terminal may be left in an unusable state after a panic.
    def self.without_catch_panics : ProgramOption
      ->(program : Program) do
        program.disable_catch_panics = true
      end
    end

    # WithoutSignals ignores OS signals.
    # Mainly useful for testing.
    def self.without_signals : ProgramOption
      ->(program : Program) do
        program.ignore_signals = true
      end
    end

    # WithoutInput disables all input
    def self.without_input : ProgramOption
      ->(program : Program) do
        program.disable_input = true
      end
    end

    # WithoutRenderer disables the renderer.
    # Output will be sent directly without rendering logic.
    def self.without_renderer : ProgramOption
      ->(program : Program) do
        program.disable_renderer = true
      end
    end

    # WithFPS sets a custom maximum fps (1-120)
    def self.with_fps(fps : Int32) : ProgramOption
      ->(program : Program) do
        program.fps = fps.clamp(1, 120)
      end
    end

    # WithFilter sets an event filter function.
    # The filter can return any Msg, or nil to ignore the event.
    def self.with_filter(&block : Model, Msg -> Msg?) : ProgramOption
      ->(program : Program) do
        program.filter = block
      end
    end

    # WithColorProfile sets the color profile to use.
    # Forces a specific color profile instead of auto-detecting.
    def self.with_color_profile(profile : Ultraviolet::ColorProfile) : ProgramOption
      ->(program : Program) do
        program.profile = profile
      end
    end

    # WithWindowSize sets the initial terminal window size.
    # Useful for testing or non-interactive environments.
    def self.with_window_size(width : Int32, height : Int32) : ProgramOption
      ->(program : Program) do
        program.width = width
        program.height = height
      end
    end

    # WithAltScreen starts the program with alternate screen enabled
    def self.with_alt_screen : ProgramOption
      ->(program : Program) do
        # Would be handled during initialization
      end
    end

    # WithMouseCellMotion enables mouse cell motion tracking
    def self.with_mouse_cell_motion : ProgramOption
      ->(program : Program) do
        # Would be handled during initialization
      end
    end

    # WithMouseAllMotion enables all mouse motion tracking
    def self.with_mouse_all_motion : ProgramOption
      ->(program : Program) do
        # Would be handled during initialization
      end
    end

    # WithReportFocus enables focus reporting
    def self.with_report_focus : ProgramOption
      ->(program : Program) do
        # Would be handled during initialization
      end
    end

    # WithBracketedPaste enables bracketed paste mode
    def self.with_bracketed_paste : ProgramOption
      ->(program : Program) do
        # Would be handled during initialization
      end
    end
  end

  # Convenience methods for creating options

  def self.with_context(ctx : ExecutionContext) : ProgramOption
    Options.with_context(ctx)
  end

  def self.with_output(output : IO) : ProgramOption
    Options.with_output(output)
  end

  def self.with_input(input : IO?) : ProgramOption
    Options.with_input(input)
  end

  def self.with_environment(env : Ultraviolet::Environ) : ProgramOption
    Options.with_environment(env)
  end

  def self.without_signal_handler : ProgramOption
    Options.without_signal_handler
  end

  def self.without_catch_panics : ProgramOption
    Options.without_catch_panics
  end

  def self.without_signals : ProgramOption
    Options.without_signals
  end

  def self.without_input : ProgramOption
    Options.without_input
  end

  def self.without_renderer : ProgramOption
    Options.without_renderer
  end

  def self.with_fps(fps : Int32) : ProgramOption
    Options.with_fps(fps)
  end

  def self.with_filter(&block : Model, Msg -> Msg?) : ProgramOption
    Options.with_filter(&block)
  end

  def self.with_color_profile(profile : Ultraviolet::ColorProfile) : ProgramOption
    Options.with_color_profile(profile)
  end

  def self.with_window_size(width : Int32, height : Int32) : ProgramOption
    Options.with_window_size(width, height)
  end

  def self.with_alt_screen : ProgramOption
    Options.with_alt_screen
  end

  def self.with_mouse_cell_motion : ProgramOption
    Options.with_mouse_cell_motion
  end

  def self.with_mouse_all_motion : ProgramOption
    Options.with_mouse_all_motion
  end

  def self.with_report_focus : ProgramOption
    Options.with_report_focus
  end

  def self.with_bracketed_paste : ProgramOption
    Options.with_bracketed_paste
  end
end
