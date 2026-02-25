# TTY handling for Tea v2-exp
# Ported from Go tty.go, tty_unix.go, tty_windows.go
# Provides terminal initialization, raw mode, and TTY operations

module Tea
  # SuspendMsg signals the program should suspend (Ctrl+Z)
  struct SuspendMsg
    include Msg
  end

  # ResumeMsg signals the program has resumed from suspend
  struct ResumeMsg
    include Msg
  end

  # TTY module for terminal operations
  module TTY
    # Open the terminal TTY for reading and writing
    # Returns {input_io, output_io}
    def self.open : {IO, IO}
      Ultraviolet.open_tty
    end

    # Check if the given IO is a terminal
    def self.terminal?(io : IO) : Bool
      io.is_a?(IO::FileDescriptor) && io.tty?
    end

    # Get the file descriptor from an IO
    def self.fd(io : IO) : Int32?
      io.as?(IO::FileDescriptor).try(&.fd)
    end
  end

  # Extend Program class with TTY functionality
  class Program
    # TTY input/output file descriptors
    @tty_input : IO::FileDescriptor? = nil
    @tty_output : IO::FileDescriptor? = nil

    # Previous TTY states for restoration
    @previous_tty_input_state : Ultraviolet::TtyState? = nil
    @previous_output_state : Ultraviolet::TtyState? = nil

    # Input reading
    @cancel_reader : Ultraviolet::CancelReader? = nil
    @input_scanner : Ultraviolet::TerminalReader? = nil
    @read_loop_done : Channel(Nil)? = nil

    # Terminal dimensions
    @pixel_width : Int32 = 0
    @pixel_height : Int32 = 0

    # Suspension support flag
    SUSPEND_SUPPORTED = true

    # Suspend the program (send SIGTSTP)
    def suspend
      # Release terminal before suspending
      if err = release_terminal(true)
        # If we can't release input, abort
        return
      end

      # Suspend the process
      suspend_process

      # Restore terminal after resuming
      restore_terminal rescue nil

      # Send resume message
      spawn { send(ResumeMsg.new) }
    end

    # Initialize terminal (called at program start)
    def init_terminal : Exception?
      return nil if @disable_renderer
      init_input
    end

    # Restore terminal to original state
    def restore_terminal_state : Exception?
      # Flush queued commands
      flush rescue nil

      # Restore input
      restore_input
    end

    # Restore TTY input to original state
    def restore_input : Exception?
      if tty_input = @tty_input
        if prev_state = @previous_tty_input_state
          # Restore using ultraviolet's restore mechanism
          # TODO: implement term restore in ultraviolet
        end
      end

      if tty_output = @tty_output
        if prev_state = @previous_output_state
          # Restore using ultraviolet's restore mechanism
          # TODO: implement term restore in ultraviolet
        end
      end

      nil
    end

    # (Re)start input reading
    def init_input_reader(cancel : Bool = false) : Exception?
      if cancel && (reader = @cancel_reader)
        reader.cancel
        wait_for_read_loop
      end

      term_type = @env.get("TERM", "")

      # Initialize cancelable reader
      if input = @input
        @cancel_reader = Ultraviolet::CancelReader.new(input)
      end

      # Initialize terminal reader
      if cancel_reader = @cancel_reader
        @input_scanner = Ultraviolet::TerminalReader.new(cancel_reader, term_type)
        @input_scanner.try(&.logger = @logger)
      end

      @read_loop_done = Channel(Nil).new(1)

      # Start read loop in background
      spawn { read_loop }

      nil
    end

    # Read loop for input events
    private def read_loop
      done = @read_loop_done
      return unless done

      begin
        if scanner = @input_scanner
          # Stream events from input scanner
          # TODO: implement event streaming
          while @running
            # Read and process events
            sleep 1.millisecond
          end
        end
      rescue ex
        @errs.send(ex) rescue nil
      ensure
        done.send(nil) rescue nil
      end
    end

    # Wait for read loop to finish
    private def wait_for_read_loop
      if done = @read_loop_done
        select
        when done.receive
          # Loop finished
        when timeout(500.milliseconds)
          # Timeout - loop may be hanging
        end
      end
    end

    # Check and report terminal resize
    def check_resize
      return unless tty_output = @tty_output

      # Get current terminal size
      if tty_output.is_a?(IO::FileDescriptor)
        begin
          size = Ultraviolet::SizeNotifier.size(tty_output)
          @width = size.width
          @height = size.height
          send(WindowSizeMsg.new(@width, @height))
        rescue ex
          @errs.send(ex) rescue nil
        end
      end
    end

    # Initialize TTY input (set raw mode, etc.)
    # Platform-specific implementation
    def init_input : Exception?
      # Check if input is a terminal
      if input = @input
        if input.is_a?(IO::FileDescriptor) && input.tty?
          @tty_input = input
          # TODO: Make raw mode via ultraviolet
          # @previous_tty_input_state = make_raw(@tty_input)

          # Check for optimized cursor movements
          # TODO: check_optimized_movements
        end
      end

      # Check if output is a terminal
      if output = @output
        if output.is_a?(IO::FileDescriptor) && output.tty?
          @tty_output = output
        end
      end

      nil
    end

    # Suspend the process (Unix-specific)
    # Uses SIGTSTP/SIGCONT signals
    private def suspend_process
      {% if flag?(:unix) %}
        # Set up CONT signal handler
        cont_channel = Channel(Nil).new(1)

        Signal::CONT.trap do
          cont_channel.try_send(nil)
        end

        # Send TSTP to suspend
        Process.kill(Signal::TSTP, 0)

        # Wait for CONT signal
        cont_channel.receive

        # Reset signal handler
        Signal::CONT.reset
      {% end %}
    end

    # Listen for window resize events (SIGWINCH on Unix)
    def listen_for_resize(done : Channel(Nil))
      {% if flag?(:unix) %}
        # Set up SIGWINCH handler
        Signal::WINCH.trap do
          check_resize
        end

        # Wait for done signal
        done.receive

        # Reset handler
        Signal::WINCH.reset
      {% else %}
        # Windows doesn't support SIGWINCH
        done.receive
      {% end %}
    end
  end

  # Suspend returns a command that suspends the program
  def self.suspend : Cmd
    -> : Msg? { SuspendMsg.new }
  end
end
