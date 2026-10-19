require "spec"
require "../src/bubbletea"

# Quits as soon as it starts, so the startup query path is exercised.
class QuerySkipQuitModel
  include Tea::Model

  def init : Tea::Cmd?
    Tea.quit
  end

  def update(msg : Tea::Msg) : Tuple(Tea::Model, Tea::Cmd?)
    {self, nil}
  end

  def view : Tea::View
    Tea::View.new("")
  end
end

# Issues every terminal query whose reply must be read from the input reader,
# then quits once all of them have been handled.
class QuerySkipBatchModel
  include Tea::Model

  QUERY_COUNT = 8

  @handled = 0

  def init : Tea::Cmd?
    Tea.batch(
      Tea.request_background_color,
      Tea.request_foreground_color,
      Tea.request_cursor_color,
      Tea.read_clipboard,
      Tea.read_primary_clipboard,
      Tea.request_terminal_version,
      Tea.request_capability("TN"),
      Tea.request_cursor_position,
    )
  end

  def update(msg : Tea::Msg) : Tuple(Tea::Model, Tea::Cmd?)
    case msg
    when Tea::RequestBackgroundColorMsg, Tea::RequestForegroundColorMsg,
         Tea::RequestCursorColorMsg, Tea::ReadClipboardMsg,
         Tea::ReadPrimaryClipboardMsg, Tea::TerminalVersionRequestMsg,
         Tea::RequestCapabilityMsg, Tea::RequestCursorPositionMsg
      @handled += 1
      return {self, Tea.quit} if @handled == QUERY_COUNT
    end

    {self, nil}
  end

  def view : Tea::View
    Tea::View.new("")
  end
end

private def run_query_program(model : Tea::Model, input : IO?) : String
  output = IO::Memory.new
  program = Tea.new_program(
    model,
    Tea.with_input(input),
    Tea.with_output(output),
    Tea.with_environment(
      Ultraviolet::Environ.new(["TERM=xterm-256color", "TERM_PROGRAM=ghostty"])
    ),
    Tea.without_signals,
  )

  _model, err = program.run
  raise err if err

  output.to_s
end

private def terminal_query_sequences : Array(String)
  [
    Ansi::RequestSystemClipboard,
    Ansi::RequestPrimaryClipboard,
    Ansi::RequestBackgroundColor,
    Ansi::RequestForegroundColor,
    Ansi::RequestCursorColor,
    Ansi::RequestNameVersion,
    "\eP+q544E\e\\", # RequestTermcap("TN")
    Ansi::RequestCursorPositionReport,
  ]
end

describe "terminal queries without input" do
  # Regression for https://github.com/charmbracelet/gum/issues/1118:
  # programs without input cannot read query replies, so the terminal's
  # responses leak into the shell after exit.
  startup_query = Ansi::RequestModeSynchronizedOutput + Ansi::RequestModeUnicodeCore

  it "skips the startup capability query when input is disabled" do
    output = run_query_program(QuerySkipQuitModel.new, nil)

    output.should_not contain(startup_query)
  end

  it "sends the startup capability query when input is enabled" do
    output = run_query_program(QuerySkipQuitModel.new, IO::Memory.new(""))

    output.should contain(startup_query)
  end

  it "skips input-dependent commands when input is disabled" do
    output = run_query_program(QuerySkipBatchModel.new, nil)

    terminal_query_sequences.each do |query|
      output.should_not contain(query)
    end
  end

  it "sends input-dependent commands when input is enabled" do
    output = run_query_program(QuerySkipBatchModel.new, IO::Memory.new(""))

    terminal_query_sequences.each do |query|
      output.should contain(query)
    end
  end
end
