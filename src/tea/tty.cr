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
    @console : Ultraviolet::Console? = nil

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
    @reader_stop : Channel(Nil)? = nil

    # Terminal dimensions
    @pixel_width : Int32 = 0
    @pixel_height : Int32 = 0

    # Suspension support flag
    SUSPEND_SUPPORTED = true

    # Suspend the program (send SIGTSTP)
    def suspend
      # Release terminal before suspending
      if release_terminal(true)
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
      return if @disable_renderer
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
      if stop = @reader_stop
        stop.close rescue nil
        @reader_stop = nil
      end

      @cancel_reader.try(&.cancel)
      wait_for_read_loop

      begin
        @console.try(&.restore)
      rescue ex
        return ex
      end

      nil
    end

    # (Re)start input reading
    def init_input_reader(cancel : Bool = false) : Exception?
      if cancel && (reader = @cancel_reader)
        reader.cancel
        wait_for_read_loop
      end

      term_type = @env.getenv("TERM")

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
      @reader_stop = Channel(Nil).new(1)

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
          eventc = Channel(Ultraviolet::Event).new
          stop = @reader_stop

          spawn do
            begin
              scanner.stream_events(eventc, stop)
            rescue ex
              @errs.send(ex) rescue nil
            ensure
              eventc.close
            end
          end

          while @running
            event = eventc.receive?
            break unless event
            send(translate_input_event(event))
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
      if console = @console
        width, height = console.size
        @width = width
        @height = height
        send(WindowSizeMsg.new(@width, @height))
      end
    rescue ex
      # Bubble Tea treats size probing as best-effort; don't terminate the
      # program when a terminal reports ioctl errors.
      if ex.is_a?(IO::Error) && ex.message.to_s.includes?("ioctl")
        return
      end
      @errs.send(ex) rescue nil
    end

    # Initialize TTY input (set raw mode, etc.)
    # Platform-specific implementation
    def init_input : Exception?
      @input ||= STDIN
      @output ||= STDOUT

      if input = @input
        @tty_input = input.as?(IO::FileDescriptor)
      end
      if output = @output
        @tty_output = output.as?(IO::FileDescriptor)
      end

      begin
        @console = Ultraviolet::Console.new(@input, @output, @env.items)
        @console.try(&.make_raw)
      rescue ex
        return ex
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
          cont_channel.send(nil) rescue nil
        end

        # Send TSTP to suspend
        Process.signal(Signal::TSTP, 0)

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
