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
      if err = restore_input
        return err
      end

      # Hard-reset terminal modes on real TTYs to avoid mode leakage when
      # shutdown ordering races with renderer/input teardown.
      if (tty_out = @tty_output) && tty_out.tty?
        begin
          tty_out << Ansi::ResetModifyOtherKeys
          tty_out << Ansi.kitty_keyboard(0, 1)
          tty_out << Ansi::ResetModeBracketedPaste
          tty_out << Ansi::ResetModeFocusEvent
          tty_out << Ansi::ResetModeMouseButtonEvent
          tty_out << Ansi::ResetModeMouseAnyEvent
          tty_out << Ansi::ResetModeMouseExtSgr
          tty_out << Ansi::ResetModeAltScreenSaveCursor
          tty_out << Ansi::SetModeTextCursorEnable
          tty_out << Ansi::ResetModeSynchronizedOutput
          tty_out << Ansi::ResetModeUnicodeCore
          tty_out.flush
        rescue ex
          return ex
        end
      end

      nil
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
        @cancel_reader.try(&.close)
      rescue ex
        return ex
      ensure
        @cancel_reader = nil
        @input_scanner = nil
      end

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
        begin
          reader.close
        rescue ex
          return ex
        ensure
          @cancel_reader = nil
        end
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
        STDERR.puts("tea: input scanner initialized term=#{term_type.inspect}") if ENV["TEA_DEBUG_IO"]?
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
          STDERR.puts("tea: read_loop start") if ENV["TEA_DEBUG_IO"]?

          spawn do
            begin
              scanner.stream_events(eventc, stop)
            rescue ex
              STDERR.puts("tea: stream_events error #{ex.class}: #{ex.message}") if ENV["TEA_DEBUG_IO"]?
              if @running && !@shutdown_done
                @errs.send(ex) rescue nil
              end
            ensure
              STDERR.puts("tea: stream_events finished") if ENV["TEA_DEBUG_IO"]?
              eventc.close
            end
          end

          while @running
            event = eventc.receive?
            break unless event
            STDERR.puts("tea: event #{event.class}") if ENV["TEA_DEBUG_IO"]?
            send(translate_input_event(event))
          end
        end
      rescue ex
        STDERR.puts("tea: read_loop error #{ex.class}: #{ex.message}") if ENV["TEA_DEBUG_IO"]?
        if @running && !@shutdown_done
          @errs.send(ex) rescue nil
        end
      ensure
        STDERR.puts("tea: read_loop end") if ENV["TEA_DEBUG_IO"]?
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
      if tty_output = @tty_output
        ws = uninitialized LibC::Winsize
        if LibC.ioctl(tty_output.fd, Ultraviolet::TIOCGWINSZ, pointerof(ws).as(Void*)) == 0
          width = ws.ws_col.to_i
          height = ws.ws_row.to_i
          if width > 0 && height > 0
            @width, @height = width, height
            spawn { send(WindowSizeMsg.new(@width, @height)) }
            return
          end
        end
      elsif @width > 0 && @height > 0
        # Non-TTY outputs (e.g. IO::Memory parity harnesses) still need an
        # initial size event when WithWindowSize has been configured.
        spawn { send(WindowSizeMsg.new(@width, @height)) }
        return
      end

      # Ensure models still get one initial size message.
      send_fallback_window_size
    end

    private def send_fallback_window_size
      if @width <= 0 || @height <= 0
        @width = 80
        @height = 24
      end
      spawn { send(WindowSizeMsg.new(@width, @height)) }
    end

    # Initialize TTY input (set raw mode, etc.)
    # Platform-specific implementation
    def init_input : Exception?
      @tty_input = nil
      @tty_output = nil

      if input = @input
        if fd = input.as?(IO::FileDescriptor)
          @tty_input = fd if fd.tty?
        end
      end
      if output = @output
        if fd = output.as?(IO::FileDescriptor)
          @tty_output = fd if fd.tty?
        end
      end

      input_is_tty = @tty_input.try(&.tty?) || false
      _output_is_tty = @tty_output.try(&.tty?) || false
      if ENV["TEA_DEBUG_IO"]?
        STDERR.puts("tea: init_input input_tty=#{input_is_tty} output_tty=#{_output_is_tty} input=#{@input.class} output=#{@output.try(&.class)}")
      end

      # Go parity: raw mode is initialized based on input terminal capability.
      # Output TTY status is tracked independently for resize handling/queries.
      if input_is_tty
        begin
          @console = Ultraviolet::Console.new(@input, @output, @env.items)
          state = @console.try(&.make_raw)
          check_optimized_movements(state)
        rescue ex
          return ex
        end
      end

      nil
    end

    private def check_optimized_movements(state : Ultraviolet::TtyState?) : Nil
      return unless state

      {% if flag?(:win32) %}
        @use_hard_tabs = true
        @use_backspace = true
      {% elsif flag?(:darwin) || flag?(:linux) || flag?(:solaris) || flag?(:aix) %}
        @use_hard_tabs = Ultraviolet.supports_hard_tabs(state.c_oflag.to_u64)
        @use_backspace = Ultraviolet.supports_backspace(state.c_lflag.to_u64)
      {% elsif flag?(:dragonfly) || flag?(:freebsd) %}
        @use_hard_tabs = Ultraviolet.supports_hard_tabs(state.c_oflag.to_u64)
      {% else %}
      {% end %}
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
