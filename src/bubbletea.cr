# Bubbletea - Crystal port of the Go Bubble Tea TUI framework
# Version 2.0.0-exp (v2-exp branch)

require "./tea"

# Re-export the Tea module as Bubbletea for compatibility
module Bubbletea
  # Include all Tea constants and methods
  extend self

  # Main types
  alias Cmd = Tea::Cmd
  alias Model = Tea::Model
  alias View = Tea::View
  alias Program = Tea::Program
  alias ProgramOption = Tea::ProgramOption
  alias ExecutionContext = Tea::ExecutionContext

  # Key types
  alias Key = Tea::Key
  alias KeyMod = Tea::KeyMod
  alias KeyPressMsg = Tea::KeyPressMsg
  alias KeyReleaseMsg = Tea::KeyReleaseMsg
  alias KeyMsg = Tea::KeyMsg

  # Mouse types
  alias Mouse = Tea::Mouse
  alias MouseButton = Tea::MouseButton
  alias MouseMsg = Tea::MouseMsg
  alias MouseClickMsg = Tea::MouseClickMsg
  alias MouseReleaseMsg = Tea::MouseReleaseMsg
  alias MouseWheelMsg = Tea::MouseWheelMsg
  alias MouseMotionMsg = Tea::MouseMotionMsg

  # Screen
  alias Screen = Tea::Screen

  # Message types
  alias QuitMsg = Tea::QuitMsg
  alias SuspendMsg = Tea::SuspendMsg
  alias ResumeMsg = Tea::ResumeMsg
  alias InterruptMsg = Tea::InterruptMsg
  alias WindowSizeMsg = Tea::WindowSizeMsg
  alias FocusMsg = Tea::FocusMsg
  alias BlurMsg = Tea::BlurMsg
  alias PasteMsg = Tea::PasteMsg
  alias CursorPositionMsg = Tea::CursorPositionMsg
  alias CapabilityMsg = Tea::CapabilityMsg
  alias TerminalVersionMsg = Tea::TerminalVersionMsg
  alias ColorProfileMsg = Tea::ColorProfileMsg
  alias KeyboardEnhancementsMsg = Tea::KeyboardEnhancementsMsg
  alias ModeReportMsg = Tea::ModeReportMsg
  alias EnvMsg = Tea::EnvMsg

  # Clipboard message types
  alias ClipboardMsg = Tea::ClipboardMsg
  alias SetClipboardMsg = Tea::SetClipboardMsg
  alias ReadClipboardMsg = Tea::ReadClipboardMsg
  alias SetPrimaryClipboardMsg = Tea::SetPrimaryClipboardMsg
  alias ReadPrimaryClipboardMsg = Tea::ReadPrimaryClipboardMsg

  # Exec types
  alias ExecCommand = Tea::ExecCommand
  alias ExecCallback = Tea::ExecCallback
  alias ExecMsg = Tea::ExecMsg
  alias PrintLineMsg = Tea::PrintLineMsg

  # Command message types
  alias BatchMsg = Tea::BatchMsg
  alias SequenceMsg = Tea::SequenceMsg
  alias SetWindowTitleMsg = Tea::SetWindowTitleMsg

  # Other types
  alias Cursor = Tea::Cursor
  alias CursorStyle = Tea::CursorStyle
  alias ProgressBar = Tea::ProgressBar
  alias MouseMode = Tea::MouseMode
  alias KeyboardEnhancements = Tea::KeyboardEnhancements
  alias Value = Tea::Value

  # Options
  alias Options = Tea::Options

  # Error types
  alias ProgramPanicError = Tea::ProgramPanicError
  alias ProgramKilledError = Tea::ProgramKilledError
  alias InterruptedError = Tea::InterruptedError

  # Delegate functions
  def wrap(value)
    Tea.wrap(value)
  end

  def [](value)
    Tea[value]
  end

  def batch(*commands)
    Tea.batch(*commands)
  end

  def sequence(*commands)
    Tea.sequence(*commands)
  end

  def sequentially(*commands)
    Tea.sequentially(*commands)
  end

  def every(duration, fn : Time -> Tea::Msg?)
    Tea.every(duration) { |time| fn.call(time) }
  end

  def tick(duration, fn : Time -> Tea::Msg?)
    Tea.tick(duration) { |time| fn.call(time) }
  end

  # ameba:disable Naming/AccessorMethodName
  def set_window_title(title)
    Tea.set_window_title(title)
  end

  def window_size
    Tea.window_size
  end

  def new_program(model, *options)
    Tea.new_program(model, *options)
  end

  def quit
    Tea.quit
  end

  def suspend
    Tea.suspend
  end

  def interrupt
    Tea.interrupt
  end

  def key(rune_or_type, modifiers = 0)
    Tea.key(rune_or_type, modifiers)
  end

  def mouse_click(x, y, button = Ultraviolet::MouseButton::Left)
    Tea.mouse_click(x, y, button)
  end

  def mouse_release(x, y, button = Ultraviolet::MouseButton::Left)
    Tea.mouse_release(x, y, button)
  end

  def mouse_wheel(x, y, direction)
    Tea.mouse_wheel(x, y, direction)
  end

  def mouse_motion(x, y)
    Tea.mouse_motion(x, y)
  end

  def alt_screen
    Tea.alt_screen
  end

  def exit_alt_screen
    Tea.exit_alt_screen
  end

  def enable_mouse
    Tea.enable_mouse
  end

  def disable_mouse
    Tea.disable_mouse
  end

  def clear_screen
    Tea.clear_screen
  end

  def hide_cursor
    Tea.hide_cursor
  end

  def show_cursor
    Tea.show_cursor
  end

  def with_context(ctx)
    Tea.with_context(ctx)
  end

  def without_input
    Tea.without_input
  end

  def without_renderer
    Tea.without_renderer
  end

  def with_fps(fps)
    Tea.with_fps(fps)
  end

  def with_filter(&block)
    Tea.with_filter(&block)
  end

  def with_alt_screen
    Tea.with_alt_screen
  end

  def with_mouse_cell_motion
    Tea.with_mouse_cell_motion
  end

  def with_mouse_all_motion
    Tea.with_mouse_all_motion
  end

  def with_report_focus
    Tea.with_report_focus
  end

  # Clipboard functions
  # ameba:disable Naming/AccessorMethodName
  def set_clipboard(content)
    Tea.set_clipboard(content)
  end

  def read_clipboard
    Tea.read_clipboard
  end

  # ameba:disable Naming/AccessorMethodName
  def set_primary_clipboard(content)
    Tea.set_primary_clipboard(content)
  end

  def read_primary_clipboard
    Tea.read_primary_clipboard
  end

  # Exec functions
  def exec(cmd, callback = nil)
    Tea.exec(cmd, callback)
  end

  def exec_process(process, callback = nil)
    Tea.exec_process(process, callback)
  end

  def exec_shell(command, callback = nil)
    Tea.exec_shell(command, callback)
  end

  def println(*args)
    Tea.println(*args)
  end

  def printf(template, *args)
    Tea.printf(template, *args)
  end

  # Constants
  VERSION   = Tea::VERSION
  KEY_NAMES = Tea::KEY_NAMES

  # KeyMod constants (from mod.go)
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

# Also make Tea available at the top level for convenience
# Users can use either `Tea` or `Bubbletea` module
