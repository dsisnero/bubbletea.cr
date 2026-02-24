# Port of github.com/charmbracelet/bubbletea v2-exp branch
# Package tea provides a framework for building rich terminal user interfaces
#
# This version ports the v2-exp branch which uses ultraviolet as the core event system.

require "time"
require "json"
require "colorful"

module Tea
  # Version
  VERSION = "0.2.0-exp"

  # Errors
  class ProgramPanicError < Exception; end

  class ProgramKilledError < Exception; end

  class InterruptedError < Exception; end

  # Base Msg module - all message types include this
  module Msg
  end

  # In Go v2-exp: type Msg = uv.Event
  # Event is an alias for Msg in our implementation
  alias Event = Msg

  # Value wraps any value to make it act as a Msg.
  # This allows primitive types like String, Int32 to be used as messages.
  struct Value(T)
    include Msg

    getter value : T

    def initialize(@value : T)
    end

    def ==(other : self)
      @value == other.value
    end

    def to_s(io)
      io << "Value(#{@value})"
    end
  end

  # Wrap any value as a Msg.
  # If the value is already a Msg, return it directly.
  # Otherwise, wrap it in Value.
  def self.wrap(value : T) : Msg forall T
    if value.is_a?(Msg)
      value
    else
      Value.new(value)
    end
  end

  # Shorthand for wrap - allows Tea[value] syntax
  def self.[](value : T) : Msg forall T
    wrap(value)
  end

  # Cmd is a function that returns a Msg (or nil).
  # In Go v2-exp: type Cmd func() Msg
  alias Cmd = Proc(Msg?)

  # Model contains the program's state as well as its core functions.
  # This is the interface that user models must implement.
  module Model
    abstract def init : Cmd?
    abstract def update(msg : Msg) : Tuple(Model, Cmd?)
    abstract def view : View
  end

  # View represents a terminal view that can be composed of multiple layers.
  # In v2-exp, View is a struct with many optional fields.
  struct View
    # Content is the screen content as styled strings with ANSI escape codes
    property content : String = ""

    # OnMouse is an optional mouse message handler
    property on_mouse : Proc(MouseMsg, Cmd?)? = nil

    # Cursor represents cursor position, style, and visibility
    property cursor : Cursor? = nil

    # BackgroundColor sets terminal background color
    property background_color : Colorful::Color? = nil

    # ForegroundColor sets terminal foreground color
    property foreground_color : Colorful::Color? = nil

    # WindowTitle sets the terminal window title
    property window_title : String = ""

    # ProgressBar shows a progress bar in the terminal
    property progress_bar : ProgressBar? = nil

    # AltScreen puts the program in the alternate screen buffer
    property? alt_screen : Bool = false

    # ReportFocus enables focus/blur message reporting
    property? report_focus : Bool = false

    # DisableBracketedPasteMode disables bracketed paste
    property? disable_bracketed_paste : Bool = false

    # MouseMode sets the mouse handling mode
    property mouse_mode : MouseMode = MouseMode::None

    # KeyboardEnhancements requests keyboard enhancement features
    property keyboard_enhancements : KeyboardEnhancements = KeyboardEnhancements.new

    def initialize(@content = "")
    end

    # Create a new view with the given content
    def self.new(content : String)
      view = View.allocate
      view.content = content
      view
    end
  end

  # ProgressBar represents a terminal progress bar
  struct ProgressBar
    property value : Float64 = 0.0
    property max : Float64 = 100.0
    property label : String = ""

    def initialize(@value = 0.0, @max = 100.0, @label = "")
    end

    def percent
      (@value / @max * 100).clamp(0.0, 100.0)
    end
  end

  # MouseMode defines how mouse events are handled
  enum MouseMode
    None
    CellMotion
    AllMotion
  end

  # KeyboardEnhancements describes requested keyboard features
  struct KeyboardEnhancements
    # ReportEventTypes requests key repeat and release events
    property? report_event_types : Bool = false

    # ReportAlternateKeys requests reporting of alternate key representations
    property? report_alternate_keys : Bool = false

    # ReportAllKeys requests reporting of all keys including non-ASCII
    property? report_all_keys : Bool = false

    # ReportAssociatedText requests reporting of associated text
    property? report_associated_text : Bool = false

    def initialize(
      @report_event_types = false,
      @report_alternate_keys = false,
      @report_all_keys = false,
      @report_associated_text = false,
    )
    end
  end

  # Cursor represents the cursor position, style, and visibility
  struct Cursor
    property x : Int32 = 0
    property y : Int32 = 0
    property? visible : Bool = true
    property style : CursorStyle = CursorStyle::Block
    property color : Colorful::Color? = nil

    def initialize(
      @x = 0,
      @y = 0,
      @visible = true,
      @style = CursorStyle::Block,
      @color = nil,
    )
    end

    def position
      {x, y}
    end
  end

  # CursorStyle defines the cursor appearance
  enum CursorStyle
    Block
    BlockBlinking
    Underline
    UnderlineBlinking
    Bar
    BarBlinking
  end

  # Program is a terminal user interface
  class Program
    # Configuration options
    property fps : Int32 = 60
    property initial_model : Model? = nil
    property? disable_input : Bool = false
    property? disable_renderer : Bool = false
    property filter : Proc(Model, Msg, Msg?)? = nil

    # Internal state
    @running : Bool = false
    @quitting : Bool = false
    @msgs = Channel(Msg).new(100)
    @cmds = Channel(Cmd).new(100)
    @mutex = Mutex.new

    def initialize(@initial_model : Model? = nil)
    end

    # Start the program with the given context
    # ameba:disable Metrics/CyclomaticComplexity
    def run(context : ExecutionContext = ExecutionContext.default) : Tuple(Model?, Exception?)
      model = @initial_model
      return {nil, Exception.new("No initial model provided")} unless model

      @running = true

      # Start command processor
      _command_processor = spawn do
        while @running
          select
          when cmd = @cmds.receive
            spawn do
              begin
                msg = cmd.call
                send(msg) if msg
              rescue ex
                # TODO: handle panic
              end
            end
          when timeout(100.milliseconds)
            # Check @running again
          end
        end
      end

      # Initialize
      cmd = model.init
      send(cmd) if cmd

      # Main event loop
      loop do
        select
        when msg = @msgs.receive
          break if @quitting

          # Apply filter if set
          if filter = @filter
            msg = filter.call(model, msg)
            next unless msg
          end

          # Handle special messages
          case msg
          when QuitMsg
            @quitting = true
            break
          when BatchMsg
            spawn { exec_batch_msg(msg) }
            next
          when SequenceMsg
            spawn { exec_sequence_msg(msg) }
            next
          when WindowSizeRequestMsg
            # TODO: trigger resize check
            next
          else
            # Update model with regular message
            model, cmd = model.update(msg)
            send(cmd) if cmd
          end
        when timeout(1.millisecond)
          # Timeout to allow checking @quitting
        end

        break if @quitting
      end

      @running = false
      {model, nil}
    rescue ex
      @running = false
      {model, ex}
    end

    # Send a command to be executed
    def send(cmd : Cmd?)
      return unless cmd
      @cmds.send(cmd) rescue nil
    end

    # Send a message to the program
    def send(msg : Msg)
      @msgs.send(msg) rescue nil
    end

    # Execute a batch message (commands run concurrently)
    private def exec_batch_msg(msg : BatchMsg)
      # TODO: implement panic catching
      commands = msg.commands
      return if commands.empty?

      done = Channel(Nil).new(commands.size)
      commands.each do |cmd|
        next unless cmd
        spawn do
          begin
            result = cmd.call
            case result
            when BatchMsg
              exec_batch_msg(result)
            when SequenceMsg
              exec_sequence_msg(result)
            else
              send(result) if result
            end
          rescue ex
            # TODO: handle panic
          end
          done.send(nil)
        end
      end
      # Wait for all commands to complete
      commands.size.times { done.receive }
    end

    # Execute a sequence message (commands run sequentially)
    private def exec_sequence_msg(msg : SequenceMsg)
      # TODO: implement panic catching
      msg.commands.each do |cmd|
        next unless cmd
        result = cmd.call
        case result
        when BatchMsg
          exec_batch_msg(result)
        when SequenceMsg
          exec_sequence_msg(result)
        else
          send(result) if result
        end
      end
    end

    # Quit the program
    def quit
      @quitting = true
      send(QuitMsg.new)
    end

    # Check if the program is running
    def running?
      @running
    end
  end

  # ExecutionContext provides context for program execution
  # Similar to Go's context.Context
  class ExecutionContext
    @cancelled : Bool = false
    @cancel_proc : Proc(Nil)? = nil

    def self.default
      new
    end

    def cancel
      @cancelled = true
      @cancel_proc.try &.call
    end

    def cancelled?
      @cancelled
    end

    def on_cancel(&block : -> Nil)
      @cancel_proc = block
    end
  end

  # ProgramOption is a function that configures a Program
  alias ProgramOption = Proc(Program, Nil)

  # Create a new program with the given model and options
  def self.new_program(model : Model, *options : ProgramOption) : Program
    program = Program.new(model)
    options.each(&.call(program))
    program
  end

  # Quit returns a command that signals the program to quit
  def self.quit : Msg
    QuitMsg.new
  end

  # Suspend returns a command that suspends the program
  def self.suspend : Msg
    SuspendMsg.new
  end

  # Interrupt returns a command that interrupts the program
  def self.interrupt : Msg
    InterruptMsg.new
  end

  # KeyMod constants from mod.go
  # These are aliases to UVKeyMod values for API compatibility
  ModShift      = UVKeyMod::Shift
  ModAlt        = UVKeyMod::Alt
  ModCtrl       = UVKeyMod::Ctrl
  ModMeta       = UVKeyMod::Meta
  ModHyper      = UVKeyMod::Hyper
  ModSuper      = UVKeyMod::Super
  ModCapsLock   = UVKeyMod::CapsLock
  ModNumLock    = UVKeyMod::NumLock
  ModScrollLock = UVKeyMod::ScrollLock
end

# Require ultraviolet compatibility layer first
require "./tea/ultraviolet"

# Require all message types
require "./tea/messages"
require "./tea/commands"
require "./tea/key"
require "./tea/mouse"
require "./tea/screen"
require "./tea/options"
require "./tea/clipboard"
require "./tea/exec"
