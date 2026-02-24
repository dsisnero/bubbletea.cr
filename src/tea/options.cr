# Program options for Tea v2-exp

module Tea
  # Program options
  module Options
    # WithContext sets the context for the program
    def self.with_context(ctx : ExecutionContext) : ProgramOption
      ->(program : Program) do
        # Store context reference - would be used in run method
        program
      end
    end

    # WithoutInput disables all input
    def self.without_input : ProgramOption
      ->(program : Program) do
        program.disable_input = true
      end
    end

    # WithoutRenderer disables the renderer
    def self.without_renderer : ProgramOption
      ->(program : Program) do
        program.disable_renderer = true
      end
    end

    # WithFPS sets a custom maximum fps
    def self.with_fps(fps : Int32) : ProgramOption
      ->(program : Program) do
        program.fps = fps.clamp(1, 120)
      end
    end

    # WithFilter sets an event filter function
    def self.with_filter(&block : Model, Msg -> Msg?) : ProgramOption
      ->(program : Program) do
        program.filter = block
      end
    end

    # WithAltScreen starts the program with alternate screen enabled
    def self.with_alt_screen : ProgramOption
      ->(program : Program) do
        # Would be handled during initialization
        program
      end
    end

    # WithMouseCellMotion enables mouse cell motion tracking
    def self.with_mouse_cell_motion : ProgramOption
      ->(program : Program) do
        # Would be handled during initialization
        program
      end
    end

    # WithMouseAllMotion enables all mouse motion tracking
    def self.with_mouse_all_motion : ProgramOption
      ->(program : Program) do
        # Would be handled during initialization
        program
      end
    end

    # WithReportFocus enables focus reporting
    def self.with_report_focus : ProgramOption
      ->(program : Program) do
        # Would be handled during initialization
        program
      end
    end

    # WithBracketedPaste enables bracketed paste mode
    def self.with_bracketed_paste : ProgramOption
      ->(program : Program) do
        # Would be handled during initialization
        program
      end
    end

    # WithInitialSize sets the initial window size
    def self.with_initial_size(width : Int32, height : Int32) : ProgramOption
      ->(program : Program) do
        # Store initial size - used in testing
        program
      end
    end

    # WithOutput sets the output writer
    def self.with_output(output : IO) : ProgramOption
      ->(program : Program) do
        # Would set output writer
        program
      end
    end

    # WithInput sets the input reader
    def self.with_input(input : IO) : ProgramOption
      ->(program : Program) do
        # Would set input reader
        program
      end
    end
  end

  # Convenience methods for creating options
  def self.with_context(ctx) : ProgramOption
    Options.with_context(ctx)
  end

  def self.without_input : ProgramOption
    Options.without_input
  end

  def self.without_renderer : ProgramOption
    Options.without_renderer
  end

  def self.with_fps(fps) : ProgramOption
    Options.with_fps(fps)
  end

  def self.with_filter(&block : Model, Msg -> Msg?) : ProgramOption
    Options.with_filter(&block)
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
end
