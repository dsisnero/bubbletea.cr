# Commands for Tea v2-exp

module Tea
  # BatchMsg is a container for multiple commands
  struct BatchMsg
    include Msg
    property commands : Array(Cmd)

    def initialize(@commands : Array(Cmd))
    end
  end

  # SequenceMsg runs commands sequentially
  struct SequenceMsg
    include Msg
    property commands : Array(Cmd)

    def initialize(@commands : Array(Cmd))
    end
  end

  # WindowSizeRequestMsg requests terminal size check
  struct WindowSizeRequestMsg
    include Msg
  end

  # Batch performs a bunch of commands concurrently with no ordering guarantees
  def self.batch : Cmd?
    nil
  end

  def self.batch(*commands : Cmd?) : Cmd?
    cmds = [] of Cmd
    commands.each do |cmd|
      cmds << cmd if cmd
    end

    case cmds.size
    when 0
      nil
    when 1
      cmds[0]
    else
      -> : Msg? { BatchMsg.new(cmds) }
    end
  end

  # Sequence runs the given commands one at a time, in order
  def self.sequence : Cmd?
    nil
  end

  def self.sequence(*commands : Cmd?) : Cmd?
    cmds = [] of Cmd
    commands.each do |cmd|
      cmds << cmd if cmd
    end

    case cmds.size
    when 0
      nil
    when 1
      cmds[0]
    else
      -> : Msg? { SequenceMsg.new(cmds) }
    end
  end

  # Sequentially runs commands in order, returns first non-nil result
  # Deprecated: use sequence instead
  def self.sequentially(*commands : Cmd?)
    cmds = commands.to_a
    -> : Msg? {
      cmds.each do |cmd|
        next unless cmd
        if msg = cmd.call
          return msg
        end
      end
      nil
    }
  end

  # Every ticks in sync with the system clock
  def self.every(duration : Time::Span, &fn : Time -> Msg?) : Cmd
    timer = create_timer(duration)
    -> : Msg? {
      ts = timer.receive
      timer.stop
      timer.drain
      fn.call(ts)
    }
  end

  # Tick produces a command at a fixed interval
  def self.tick(duration : Time::Span, &fn : Time -> Msg?) : Cmd
    timer = Timer.new(duration)
    -> : Msg? {
      ts = timer.receive
      timer.stop
      timer.drain
      fn.call(ts)
    }
  end

  # Helper method to create a timer with calculated delay
  private def self.create_timer(duration : Time::Span) : Timer
    now = Time.utc
    duration_ns = duration.total_nanoseconds.to_i128
    now_ns = now.to_unix_ns

    # Calculate time until next tick aligned with duration
    truncated_ns = (now_ns // duration_ns) * duration_ns
    next_tick_ns = truncated_ns + duration_ns
    delay_ns = next_tick_ns - now_ns

    # Ensure positive delay
    delay_ns = duration_ns if delay_ns <= 0

    delay = Time::Span.new(nanoseconds: delay_ns.to_i64)
    Timer.new(delay)
  end

  # SetWindowTitle produces a command that sets the terminal title
  # ameba:disable Naming/AccessorMethodName
  def self.set_window_title(title : String) : Cmd
    -> { SetWindowTitleMsg.new(title) }
  end

  # SetWindowTitleMsg is an internal message for setting window title
  struct SetWindowTitleMsg
    include Msg
    property title : String

    def initialize(@title : String)
    end
  end

  # WindowSize produces a command that queries the terminal size
  def self.window_size : Cmd
    -> : Msg? { WindowSizeRequestMsg.new } # Requests terminal size check
  end

  # RequestWindowSize is a message that requests terminal size check.
  # Go parity: RequestWindowSize() Msg.
  def self.request_window_size : Msg
    WindowSizeRequestMsg.new
  end

  # Timer mimics Go's time.Timer using Crystal channels
  private class Timer
    def initialize(@delay : Time::Span)
      @channel = Channel(Time).new(1)
      @closed = false
      spawn_timer
    end

    private def spawn_timer
      spawn do
        sleep @delay
        begin
          @channel.send(Time.utc) unless @closed
        rescue Channel::ClosedError
          # Ignore
        end
      end
    end

    def receive : Time
      @channel.receive
    end

    def stop
      @closed = true
      @channel.close
    end

    def drain
      loop do
        break unless @channel.receive?
      end
    rescue Channel::ClosedError
      # Channel is closed
    end
  end
end
