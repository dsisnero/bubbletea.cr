# Port of github.com/charmbracelet/bubbletea package tea
require "time"
require "channel"

module Tea
  # Msg is the empty interface representing any message type.
  # We use a marker module that all message types include.
  module Msg
    # AnyMsg wraps any value to make it a Msg.
    struct Any(T)
      include Msg
      getter value : T

      def initialize(@value)
      end

      def ==(other : self)
        value == other.value
      end

      def ==(other)
        false
      end
    end

    # Convenience method to wrap a value as a Msg.
    def self.[](value)
      Any.new(value)
    end
  end

  # Cmd is a function that returns a Msg.
  # In Go: type Cmd func() Msg
  # In Crystal, we use a Proc that returns a Msg (or nil).
  alias Cmd = Proc(Msg?, Nil)

  # Internal type definitions for messages used in commands.go
  # BatchMsg is a message used to perform a bunch of commands concurrently
  struct BatchMsg
    include Msg
    getter commands : Array(Cmd)

    def initialize(@commands)
    end
  end

  # sequenceMsg is used internally to run commands in order
  struct SequenceMsg
    include Msg
    getter commands : Array(Cmd)

    def initialize(@commands)
    end
  end

  # setWindowTitleMsg is an internal message used to set the window title.
  struct SetWindowTitleMsg
    include Msg
    getter title : String

    def initialize(@title)
    end
  end

  # windowSizeMsg is a message used to query terminal size.
  struct WindowSizeMsg
    include Msg
  end

  # Timer mimics Go's time.Timer for use in Every and Tick commands.
  private class Timer
    @channel = Channel(Time).new

    def initialize(delay : Time::Span)
      spawn do
        sleep delay
        @channel.send Time.utc
      end
    end

    def channel : Channel(Time)
      @channel
    end

    def stop
      # In Go, stopping a timer prevents future ticks but does not close the channel.
      # We can't easily stop a sleeping fiber, but we can ignore the result.
      # For simplicity, we leave the fiber running; it will send to channel but nothing will receive.
      # This is acceptable for porting because bubbletea drains the channel after stop.
    end

    def drain
      # Drain any pending ticks from the channel (non-blocking)
      while @channel.receive?(wait: false)
        # discard
      end
    end
  end

  # TODO: Add other message types from other files

  # Port of commands.go functions

  # Batch performs a bunch of commands concurrently with no ordering guarantees
  # about the results. Use a Batch to return several commands.
  #
  # Example:
  #   def init : Cmd?
  #     Tea.batch(some_command, some_other_command)
  #   end
  def self.batch(*commands : Cmd?) : Cmd?
    compact_commands(BatchMsg, commands)
  end

  # Sequence runs the given commands one at a time, in order.
  def self.sequence(*commands : Cmd?) : Cmd?
    compact_commands(SequenceMsg, commands)
  end

  # compact_commands ignores any nil commands, and returns the most direct
  # command possible.
  private def self.compact_commands(msg_type, commands : Array(Cmd?)) : Cmd?
    valid_commands = commands.compact
    case valid_commands.size
    when 0
      nil
    when 1
      valid_commands[0]
    else
      -> { msg_type.new(valid_commands) }
    end
  end

  # Every is a command that ticks in sync with the system clock.
  # duration is a Time::Span
  # fn is a function that takes a Time and returns a Msg
  def self.every(duration : Time::Span, fn : Time -> Msg) : Cmd?
    now = Time.utc
    delay = now.truncate(duration).add(duration) - now
    timer = Timer.new(delay)
    -> {
      ts = timer.channel.receive
      timer.stop
      timer.drain
      fn.call(ts)
    }
  end

  # Tick produces a command at an interval independent of the system clock.
  def self.tick(duration : Time::Span, fn : Time -> Msg) : Cmd?
    timer = Timer.new(duration)
    -> {
      ts = timer.channel.receive
      timer.stop
      timer.drain
      fn.call(ts)
    }
  end

  # Sequentially produces a command that sequentially executes the given commands.
  # Deprecated: use sequence instead.
  def self.sequentially(*commands : Cmd?) : Cmd?
    -> {
      commands.each do |cmd|
        next unless cmd
        if msg = cmd.call
          return msg
        end
      end
      nil
    }
  end

  # SetWindowTitle produces a command that sets the terminal title.
  # ameba:disable Naming/AccessorMethodName
  def self.set_window_title(title : String) : Cmd?
    -> { SetWindowTitleMsg.new(title) }
  end

  # WindowSize is a command that queries the terminal for its current size.
  def self.window_size : Cmd?
    -> { WindowSizeMsg.new }
  end
end
