# Port of github.com/charmbracelet/bubbletea v2-exp branch
# Package tea provides a framework for building rich terminal user interfaces
#
# This version ports the v2-exp branch which uses ultraviolet as the core event system.

require "time"
require "json"
require "base64"
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
    # Update may return:
    # - {Model, Cmd?} (native command flow)
    # - {Model, Msg?} (Go-style convenience; message is wrapped as a Cmd)
    # - Model (state change only; no command)
    abstract def update(msg : Msg)
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

    # Go parity helper for View.SetContent().
    # ameba:disable Naming/AccessorMethodName
    def set_content(content : String) : self
      @content = content
      self
    end
    # ameba:enable Naming/AccessorMethodName
  end

  # ProgressBarState represents the state of the terminal progress bar.
  enum ProgressBarState
    None
    Default
    Error
    Indeterminate
    Warning

    # Go parity helper for ProgressBarState.String().
    def string : String
      to_s
    end
  end

  # Go parity constants for ProgressBarState values.
  ProgressBarNone = ProgressBarState::None
  ProgressBarDefault = ProgressBarState::Default
  ProgressBarError = ProgressBarState::Error
  ProgressBarIndeterminate = ProgressBarState::Indeterminate
  ProgressBarWarning = ProgressBarState::Warning

  # ProgressBar represents a terminal progress bar.
  struct ProgressBar
    property state : ProgressBarState = ProgressBarState::None
    property value : Float64 = 0.0
    property max : Float64 = 100.0
    property label : String = ""

    def initialize(@state = ProgressBarState::None, @value = 0.0, @max = 100.0, @label = "")
      unless @state.in?({ProgressBarState::None, ProgressBarState::Indeterminate})
        @value = @value.clamp(0.0, 100.0)
      end
    end

    # Backward-compatible initializer used by older specs/examples.
    def initialize(@value : Float64, @max : Float64 = 100.0, @label : String = "")
      @state = ProgressBarState::Default
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

  # Go parity constants for MouseMode values.
  MouseModeNone = MouseMode::None
  MouseModeCellMotion = MouseMode::CellMotion
  MouseModeAllMotion = MouseMode::AllMotion

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

  # Go parity helper for NewView().
  def self.new_view(content : String = "") : View
    View.new(content)
  end

  # Go parity helper for NewCursor().
  def self.new_cursor(
    x : Int32 = 0,
    y : Int32 = 0,
    visible : Bool = true,
    style : CursorStyle = CursorStyle::Block,
    color : Colorful::Color? = nil
  ) : Cursor
    Cursor.new(x, y, visible, style, color)
  end

  # Go parity helper for NewProgressBar().
  def self.new_progress_bar(
    state : ProgressBarState = ProgressBarState::None,
    value : Float64 = 0.0,
    max : Float64 = 100.0,
    label : String = ""
  ) : ProgressBar
    ProgressBar.new(state, value, max, label)
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

  # Go parity alias from cursor.go
  alias CursorShape = CursorStyle
  CursorBlock     = CursorShape::Block
  CursorUnderline = CursorShape::Underline
  CursorBar       = CursorShape::Bar

  # Position represents a 2D position
  struct Position
    property x : Int32
    property y : Int32

    def initialize(@x : Int32, @y : Int32)
    end
  end

  # Program is a terminal user interface
  class Program
    # Configuration options
    property fps : Int32 = 60
    property initial_model : Model? = nil
    property? disable_input : Bool = false
    property? disable_signal_handler : Bool = false
    property? disable_catch_panics : Bool = false
    property? disable_renderer : Bool = false
    property filter : Proc(Model, Msg, Msg?)? = nil
    property external_context : ExecutionContext? = nil

    # Terminal dimensions
    property width : Int32 = 0
    property height : Int32 = 0
    property? startup_alt_screen : Bool = false
    property startup_mouse_mode : MouseMode? = nil
    property? startup_report_focus : Bool = false
    property? startup_bracketed_paste : Bool = false

    # Internal state
    property? ignore_signals : Bool = false
    @running : Bool = false
    @quitting : Bool = false
    @killed : Bool = false
    @interrupted : Bool = false
    @msgs = Channel(Msg).new(100)
    @cmds = Channel(Cmd).new(100)
    @errs = Channel(Exception).new(10)
    @finished = Channel(Nil).new(1)
    @mutex = Mutex.new
    @signal_stop : Channel(Nil)? = nil

    # Output handling
    property output : IO? = nil
    @output_buf = IO::Memory.new

    # Input handling
    property input : IO? = nil

    # Environment
    property env : Ultraviolet::Environ = Ultraviolet::Environ.new([] of String)

    # Color profile
    property profile : Ultraviolet::ColorProfile = Ultraviolet::ColorProfile::TrueColor
    @renderer : Renderer? = nil
    @logger : Ultraviolet::Logger? = nil
    @renderer_done : Channel(Nil)? = nil

    def initialize(@initial_model : Model? = nil)
    end

    # Start the program with the given context
    # ameba:disable Metrics/CyclomaticComplexity
    def run(context : ExecutionContext? = nil) : Tuple(Model?, Exception?)
      model = @initial_model
      return {nil, Exception.new("No initial model provided")} unless model
      run_context = context || @external_context || ExecutionContext.default

      @output ||= STDOUT
      @input ||= STDIN
      if @env.items.empty?
        @env = Ultraviolet::Environ.new(ENV.map { |k, v| "#{k}=#{v}" })
      end

      @running = true
      @quitting = false
      @interrupted = false
      @killed = false

      if err = init_terminal
        return {model, err}
      end
      if err = init_input_reader
        return {model, err}
      end
      check_resize
      start_signal_handler
      init_renderer
      start_renderer

      if !@disable_renderer && should_query_synchronized_output(@env)
        execute(Ansi::RequestModeSynchronizedOutput + Ansi::RequestModeUnicodeCore)
      end

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
                handle_runtime_exception(ex)
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

      # Render initial view after startup side effects and init command dispatch.
      render(model)

      # Main event loop
      loop do
        if run_context.cancelled?
          @killed = true
          break
        end

        select
        when err = @errs.receive
          @killed = true
          shutdown(true)
          return {model, err}
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
          when InterruptMsg
            @quitting = true
            @interrupted = true
            break
          when SuspendMsg
            suspend if SUSPEND_SUPPORTED
          when BatchMsg
            spawn { exec_batch_msg(msg) }
            next
          when SequenceMsg
            spawn { exec_sequence_msg(msg) }
            next
          when MouseClickMsg, MouseReleaseMsg, MouseWheelMsg, MouseMotionMsg
            if renderer = @renderer
              if cmd = renderer.on_mouse(msg.as(MouseMsg))
                send(cmd)
              end
            end
          when ReadClipboardMsg
            execute("\e]52;c;?\a")
          when SetClipboardMsg
            execute("\e]52;c;#{Base64.strict_encode(msg.content)}\a")
          when ReadPrimaryClipboardMsg
            execute("\e]52;p;?\a")
          when SetPrimaryClipboardMsg
            execute("\e]52;p;#{Base64.strict_encode(msg.content)}\a")
          when BackgroundColorMsg
            execute("\e]11;?\a")
          when ForegroundColorMsg
            execute("\e]10;?\a")
          when CursorColorMsg
            execute("\e]12;?\a")
          when TerminalVersionRequestMsg
            execute("\e[>q")
          when RequestCapabilityMsg
            execute("\eP+q#{msg.capability}\e\\")
          when CapabilityMsg
            if (msg.content == "RGB" || msg.content == "Tc") && @profile != Ultraviolet::ColorProfile::TrueColor
              @profile = Ultraviolet::ColorProfile::TrueColor
              send(ColorProfileMsg.new(@profile))
            end
          when ColorProfileMsg
            @profile = msg.profile
            @renderer.try &.set_color_profile(msg.profile)
          when ModeReportMsg
            if msg.mode == 2026 && msg.value != 0
              @renderer.try &.syncd_updates=(true)
            elsif msg.mode == 2027
              grapheme_width = ->(value : String) { Ansi.string_width(Ansi::Method::GraphemeWidth, value) }
              @renderer.try &.set_width_method(grapheme_width)
            end
          when WindowSizeMsg
            @renderer.try &.resize(msg.width, msg.height)
            @width = msg.width
            @height = msg.height
          when WindowSizeRequestMsg
            spawn { check_resize }
          when PrintLineMsg
            @renderer.try(&.insert_above(msg.content))
          when ExecMsg
            exec(msg.cmd, msg.callback)
          when RawMsg
            # Write raw message to output without formatting
            execute(msg.msg)
          when ClearScreenMsg
            @renderer.try &.clear_screen
          end

          # Update model for all non-terminal control flow messages.
          model, cmd = normalize_update_result(model.update(msg))
          send(cmd) if cmd
          render(model)
        when timeout(1.millisecond)
          # Timeout to allow checking @quitting
        end

        break if @quitting
      end

      @running = false
      shutdown(false)
      if @interrupted
        {model, InterruptedError.new("program was interrupted")}
      elsif @killed
        {model, ProgramKilledError.new("program was killed")}
      else
        {model, nil}
      end
    rescue ex
      @running = false
      shutdown(true)
      {model, ex}
    end

    # Send a command to be executed
    def send(cmd : Cmd?)
      return unless cmd
      @cmds.send(cmd) rescue nil
    end

    # Normalize a model update return value into {Model, Cmd?}
    private def normalize_update_result(result) : Tuple(Model, Cmd?)
      case result
      when Model
        {result, nil}
      when Tuple
        unless result.size == 2
          raise Exception.new("Model#update tuple must have exactly 2 elements")
        end

        model = result[0]
        unless model.is_a?(Model)
          raise Exception.new("First element of Model#update tuple must implement Tea::Model")
        end

        {model, normalize_update_action(result[1])}
      else
        raise Exception.new("Model#update must return Model or Tuple(Model, Cmd?/Msg?)")
      end
    end

    # Accept either Cmd or Msg as the update action.
    # Returning Msg mirrors the Go ergonomics (e.g. Tea.quit).
    private def normalize_update_action(action) : Cmd?
      case action
      when Nil
        nil
      when Cmd
        action
      when Msg
        -> : Msg? { action }
      else
        raise Exception.new("Second element of Model#update tuple must be Cmd, Msg, or nil")
      end
    end

    # Send a message to the program
    def send(msg : Msg)
      @msgs.send(msg) rescue nil
    end

    # Execute a batch message (commands run concurrently)
    private def exec_batch_msg(msg : BatchMsg)
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
            handle_runtime_exception(ex)
          end
          done.send(nil)
        end
      end
      # Wait for all commands to complete
      commands.size.times { done.receive }
    end

    # Execute a sequence message (commands run sequentially)
    private def exec_sequence_msg(msg : SequenceMsg)
      msg.commands.each do |cmd|
        next unless cmd
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
          handle_runtime_exception(ex)
        end
      end
    end

    # translate_input_event translates an ultraviolet event into a Bubble Tea message
    # Matches Go's translateInputEvent function
    # ameba:disable Metrics/CyclomaticComplexity
    def translate_input_event(event : Ultraviolet::Event) : Msg
      case event
      when Ultraviolet::ClipboardEvent
        ClipboardMsg.new(event.content)
      when Ultraviolet::ForegroundColorEvent
        ForegroundColorMsg.new(convert_uv_color(event.color))
      when Ultraviolet::BackgroundColorEvent
        BackgroundColorMsg.new(convert_uv_color(event.color))
      when Ultraviolet::CursorColorEvent
        CursorColorMsg.new(convert_uv_color(event.color))
      when Ultraviolet::CursorPositionEvent
        CursorPositionMsg.new(event.x, event.y)
      when Ultraviolet::FocusEvent
        FocusMsg.new
      when Ultraviolet::BlurEvent
        BlurMsg.new
      when Ultraviolet::Key
        # Key press event from ultraviolet
        convert_uv_key(event)
      when Ultraviolet::MouseClickEvent
        MouseClickMsg.new(convert_uv_mouse(event.mouse))
      when Ultraviolet::MouseMotionEvent
        MouseMotionMsg.new(convert_uv_mouse(event.mouse))
      when Ultraviolet::MouseReleaseEvent
        MouseReleaseMsg.new(convert_uv_mouse(event.mouse))
      when Ultraviolet::MouseWheelEvent
        MouseWheelMsg.new(convert_uv_mouse(event.mouse))
      when Ultraviolet::PasteEvent
        PasteMsg.new(event.content)
      when Ultraviolet::PasteStartEvent
        PasteStartMsg.new
      when Ultraviolet::PasteEndEvent
        PasteEndMsg.new
      when Ultraviolet::WindowSizeEvent
        WindowSizeMsg.new(event.width, event.height)
      when Ultraviolet::CapabilityEvent
        CapabilityMsg.new(event.content)
      when Ultraviolet::TerminalVersionEvent
        TerminalVersionMsg.new(event.name)
      when Ultraviolet::KeyboardEnhancementsEvent
        KeyboardEnhancementsMsg.new(convert_uv_enhancements(event))
      when Ultraviolet::ModeReportEvent
        ModeReportMsg.new(event.mode, event.value)
      else
        Tea.wrap(event)
      end
    end

    # Convert ultraviolet Key to Tea Key
    private def convert_uv_key(uv_key : Ultraviolet::Key) : Key
      # Map ultraviolet key to our Key struct
      key_type = map_uv_key_type(uv_key)
      rune = nil
      if !uv_key.text.empty? && uv_key.text.size == 1
        rune = uv_key.text[0]
      end
      Key.new(
        type: key_type,
        rune: rune,
        modifiers: convert_uv_modifiers(uv_key.mod),
        is_repeat: uv_key.is_repeat?,
        alternate: nil
      )
    end

    # Map ultraviolet key type to Tea KeyType
    # ameba:disable Metrics/CyclomaticComplexity
    private def map_uv_key_type(uv_key : Ultraviolet::Key) : KeyType
      code = uv_key.code
      # This is a simplified mapping - full implementation would map all UV keys
      case code
      when Ultraviolet::KeyUp
        KeyType::Up
      when Ultraviolet::KeyDown
        KeyType::Down
      when Ultraviolet::KeyLeft
        KeyType::Left
      when Ultraviolet::KeyRight
        KeyType::Right
      when Ultraviolet::KeyHome
        KeyType::Home
      when Ultraviolet::KeyEnd
        KeyType::End
      when Ultraviolet::KeyPgUp
        KeyType::PageUp
      when Ultraviolet::KeyPgDown
        KeyType::PageDown
      when Ultraviolet::KeyInsert
        KeyType::Insert
      when Ultraviolet::KeyDelete
        KeyType::Delete
      when Ultraviolet::KeyBackspace
        KeyType::Backspace
      when Ultraviolet::KeyTab
        KeyType::Tab
      when Ultraviolet::KeyEnter
        KeyType::Enter
      when Ultraviolet::KeyEscape
        KeyType::Escape
      when Ultraviolet::KeySpace
        KeyType::Space
      when Ultraviolet::KeyF1..Ultraviolet::KeyF35
        KeyType.new(code - Ultraviolet::KeyF1 + KeyType::F1.value)
      else
        KeyType::Null
      end
    end

    # Convert ultraviolet modifiers to Tea KeyMod
    private def convert_uv_modifiers(uv_mod : Ultraviolet::KeyMod) : KeyMod
      result = 0
      result |= Ultraviolet::ModShift if Tea::KeyModHelpers.shift?(uv_mod)
      result |= Ultraviolet::ModAlt if Tea::KeyModHelpers.alt?(uv_mod)
      result |= Ultraviolet::ModCtrl if Tea::KeyModHelpers.ctrl?(uv_mod)
      result |= Ultraviolet::ModMeta if Tea::KeyModHelpers.meta?(uv_mod)
      result |= Ultraviolet::ModSuper if Tea::KeyModHelpers.super?(uv_mod)
      result |= Ultraviolet::ModHyper if Tea::KeyModHelpers.hyper?(uv_mod)
      result
    end

    # Convert ultraviolet Mouse to Tea Mouse
    private def convert_uv_mouse(uv_mouse : Ultraviolet::Mouse) : Mouse
      Mouse.new(
        x: uv_mouse.x,
        y: uv_mouse.y,
        button: convert_uv_mouse_button(uv_mouse.button),
        modifiers: convert_uv_modifiers(uv_mouse.mod)
      )
    end

    # Convert ultraviolet MouseButton to Tea MouseButton
    private def convert_uv_mouse_button(uv_button : Ultraviolet::MouseButton) : MouseButton
      case uv_button
      when Ultraviolet::MouseButton::Left
        Ultraviolet::MouseButton::Left
      when Ultraviolet::MouseButton::Middle
        Ultraviolet::MouseButton::Middle
      when Ultraviolet::MouseButton::Right
        Ultraviolet::MouseButton::Right
      when Ultraviolet::MouseButton::WheelUp
        Ultraviolet::MouseButton::WheelUp
      when Ultraviolet::MouseButton::WheelDown
        Ultraviolet::MouseButton::WheelDown
      when Ultraviolet::MouseButton::WheelLeft
        Ultraviolet::MouseButton::WheelLeft
      when Ultraviolet::MouseButton::WheelRight
        Ultraviolet::MouseButton::WheelRight
      when Ultraviolet::MouseButton::Backward
        Ultraviolet::MouseButton::Backward
      when Ultraviolet::MouseButton::Forward
        Ultraviolet::MouseButton::Forward
      when Ultraviolet::MouseButton::Button10
        Ultraviolet::MouseButton::Button10
      when Ultraviolet::MouseButton::Button11
        Ultraviolet::MouseButton::Button11
      else
        Ultraviolet::MouseButton::None
      end
    end

    # Convert ultraviolet KeyboardEnhancementsEvent to Tea KeyboardEnhancements
    private def convert_uv_enhancements(uv_event : Ultraviolet::KeyboardEnhancementsEvent) : KeyboardEnhancements
      enhancements = KeyboardEnhancements.new
      # Map UV flags to Tea enhancements
      enhancements.report_event_types = uv_event.supports_event_types?
      enhancements.report_alternate_keys = uv_event.supports_key_disambiguation?
      enhancements.report_all_keys = uv_event.supports_uniform_key_layout?
      enhancements
    end

    private def convert_uv_color(uv_color : Ultraviolet::Color) : Colorful::Color
      Colorful::Color.new(
        uv_color.r.to_f64 / 255.0,
        uv_color.g.to_f64 / 255.0,
        uv_color.b.to_f64 / 255.0
      )
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

    # Kill stops the program immediately and restores terminal state
    def kill
      @killed = true
      @quitting = true
      @running = false
      shutdown(true)
    end

    # Wait blocks until the program finishes
    def wait
      @finished.receive
    end

    # Execute writes an ANSI sequence to the output buffer
    def execute(sequence : String)
      @mutex.synchronize do
        @output_buf << sequence
      end
    end

    # Flush writes the output buffer to the actual output
    def flush
      @mutex.synchronize do
        return if @output_buf.size == 0
        if output = @output
          output.write(@output_buf.to_slice)
          output.flush
        end
        @output_buf.clear
      end
    end

    # Shutdown performs cleanup and restores terminal state
    def shutdown(kill : Bool)
      @running = false
      stop_signal_handler
      @cancel_reader.try(&.cancel)
      wait_for_read_loop unless kill
      stop_renderer(kill)
      restore_terminal_state rescue nil
      @finished.send(nil) rescue nil
    end

    # exec runs an ExecCommand and delivers results to the program
    # Matches Go's exec method logic exactly
    def exec(cmd : ExecCommand, callback : ExecCallback?)
      if err = release_terminal(false)
        # If we can't release input, abort
        if callback
          spawn { send(callback.call(err)) }
        end
        return
      end

      # Set up command I/O - these are method calls, not assignments
      if input = @input
        cmd.set_stdin(input)
      end
      if output = @output
        cmd.set_stdout(output)
        cmd.set_stderr(output)
      end

      # Execute system command
      begin
        cmd.run
      rescue ex
        # If run fails, try to restore terminal and send error
        restore_terminal rescue nil
        if callback
          spawn { send(callback.call(ex)) }
        end
        return
      end

      # Have the program re-capture input
      err = restore_terminal
      if callback
        spawn { send(callback.call(err)) }
      end
    end

    # releaseTerminal releases terminal control for external commands
    def release_terminal(reset : Bool) : Exception?
      begin
        flush if reset
      rescue ex
        return ex
      end

      err = restore_input
      return err if err

      nil
    end

    # restore_terminal restores terminal control after external commands
    def restore_terminal : Exception?
      err = init_input
      return err if err

      err = init_input_reader(true)
      return err if err

      nil
    end

    # render renders the current model view
    private def render(model : Model)
      if renderer = @renderer
        view = model.view
        view.alt_screen = true if @startup_alt_screen
        if mode = @startup_mouse_mode
          view.mouse_mode = mode if view.mouse_mode == MouseMode::None
        end
        view.report_focus = true if @startup_report_focus
        view.disable_bracketed_paste = false if @startup_bracketed_paste
        renderer.render(view)
      end
    end

    private def init_renderer
      if @disable_renderer
        @renderer = NilRenderer.new
      else
        width = @width > 0 ? @width : 80
        height = @height > 0 ? @height : 24
        output = @output || STDOUT
        @renderer = CursedRenderer.new(output, @env, width, height)
      end
      @renderer.try &.set_color_profile(@profile)
    end

    private def start_renderer
      renderer = @renderer
      return unless renderer

      done = Channel(Nil).new(1)
      @renderer_done = done
      interval = (1.0 / @fps).seconds

      renderer.start

      spawn do
        loop do
          select
          when done.receive
            break
          when timeout(interval)
            flush
            renderer.flush(false)
          end
        end
      end
    end

    private def stop_renderer(kill : Bool)
      if renderer = @renderer
        if done = @renderer_done
          done.send(nil) rescue nil
          @renderer_done = nil
        end
        renderer.flush(true) unless kill
        renderer.close
      end
    end

    private def handle_runtime_exception(ex : Exception)
      if @disable_catch_panics
        @errs.send(ex) rescue nil
      else
        @errs.send(ProgramPanicError.new("program experienced a panic: #{ex.message}")) rescue nil
      end
    end

    private def start_signal_handler
      return if @disable_signal_handler
      return if @ignore_signals

      stop = Channel(Nil).new(1)
      @signal_stop = stop

      {% if flag?(:unix) %}
        Signal::INT.trap do
          send(InterruptMsg.new) unless @ignore_signals
        end

        Signal::TERM.trap do
          send(QuitMsg.new) unless @ignore_signals
        end

        spawn do
          stop.receive
          Signal::INT.reset
          Signal::TERM.reset
        end
      {% end %}
    end

    private def stop_signal_handler
      if stop = @signal_stop
        stop.send(nil) rescue nil
        @signal_stop = nil
      end
    end

    # Matches Go's shouldQuerySynchronizedOutput terminal heuristic.
    private def should_query_synchronized_output(environ : Ultraviolet::Environ) : Bool
      term_type = environ.getenv("TERM")
      term_program, has_term_program = environ.lookup_env("TERM_PROGRAM")
      _ssh_tty, has_ssh_tty = environ.lookup_env("SSH_TTY")
      _wt_session, has_wt_session = environ.lookup_env("WT_SESSION")

      (!has_term_program && !has_ssh_tty) ||
        has_wt_session ||
        (has_term_program && !term_program.includes?("Apple") && !has_ssh_tty) ||
        term_type.includes?("ghostty") ||
        term_type.includes?("wezterm") ||
        term_type.includes?("alacritty") ||
        term_type.includes?("kitty") ||
        term_type.includes?("rio")
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
  def self.quit : Cmd
    -> : Msg? { QuitMsg.new }
  end

  # Suspend returns a command that suspends the program
  def self.suspend : Cmd
    -> : Msg? { SuspendMsg.new }
  end

  # Interrupt returns a command that interrupts the program
  def self.interrupt : Cmd
    -> : Msg? { InterruptMsg.new }
  end

  # KeyMod constants from mod.go
  # These are aliases to Ultraviolet values for API compatibility
  ModShift      = Ultraviolet::ModShift
  ModAlt        = Ultraviolet::ModAlt
  ModCtrl       = Ultraviolet::ModCtrl
  ModMeta       = Ultraviolet::ModMeta
  ModHyper      = Ultraviolet::ModHyper
  ModSuper      = Ultraviolet::ModSuper
  ModCapsLock   = Ultraviolet::ModCapsLock
  ModNumLock    = Ultraviolet::ModNumLock
  ModScrollLock = Ultraviolet::ModScrollLock
end

# Require ultraviolet shard (core terminal library)
require "ultraviolet"

# Require Tea-specific extensions to ultraviolet types (adds enum methods)
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

# Require renderer implementations
require "./tea/renderer"
require "./tea/cursed_renderer"
require "./tea/nil_renderer"

# Require TTY and signal handling
require "./tea/tty"

# Require logging
require "./tea/logging"
