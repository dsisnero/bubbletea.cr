# External command execution for Tea v2-exp
# Ported from Go exec.go

require "process"

module Tea
  # ExecCommand interface for running external commands
  # This is satisfied by Process or custom implementations
  module ExecCommand
    abstract def run : Nil
    # Crystal idiom: `stdin=`, `stdout=`, `stderr=`.
    # Kept as Go-parity API names.
    # ameba:disable Naming/AccessorMethodName
    abstract def set_stdin(reader : IO)
    # ameba:disable Naming/AccessorMethodName
    abstract def set_stdout(writer : IO)
    # ameba:disable Naming/AccessorMethodName
    abstract def set_stderr(writer : IO)
    # ameba:enable Naming/AccessorMethodName
  end

  # ExecCallback is called after command execution with any error
  alias ExecCallback = Proc(Exception?, Msg?)

  # execMsg is used internally to run an ExecCommand
  struct ExecMsg
    include Msg
    property cmd : ExecCommand
    property callback : ExecCallback?

    def initialize(@cmd : ExecCommand, @callback : ExecCallback? = nil)
    end
  end

  # Exec runs an ExecCommand in a blocking fashion, pausing the Program
  # while execution is running and resuming when complete
  def self.exec(cmd : ExecCommand, callback : ExecCallback? = nil) : Cmd
    -> : Msg? { ExecMsg.new(cmd, callback) }
  end

  # ExecProcess runs the given executable in a blocking fashion.
  # This mirrors Go's exec.Command + tea.ExecProcess behavior: the command
  # is configured first, then started during program exec with stdio attached.
  def self.exec_process(command : String, args : Array(String) = [] of String, callback : ExecCallback? = nil) : Cmd
    exec(OSExecCommand.new(command, args), callback)
  end

  # Convenience method to exec a shell command
  def self.exec_shell(command : String, callback : ExecCallback? = nil) : Cmd
    exec(ShellCommand.new(command), callback)
  end

  # OSExecCommand mirrors Go's *exec.Cmd: configure first, then run.
  class OSExecCommand
    include ExecCommand

    @command : String
    @args : Array(String)
    @stdin : IO? = nil
    @stdout : IO? = nil
    @stderr : IO? = nil

    def initialize(@command : String, @args : Array(String) = [] of String)
    end

    # ameba:disable Naming/AccessorMethodName
    def set_stdin(reader : IO)
      @stdin ||= reader
    end

    # ameba:disable Naming/AccessorMethodName
    def set_stdout(writer : IO)
      @stdout ||= writer
    end

    # ameba:disable Naming/AccessorMethodName
    def set_stderr(writer : IO)
      @stderr ||= writer
    end

    # ameba:enable Naming/AccessorMethodName

    def run : Nil
      input = @stdin ? @stdin.not_nil! : Process::Redirect::Inherit
      output = @stdout ? @stdout.not_nil! : Process::Redirect::Inherit
      error = @stderr ? @stderr.not_nil! : Process::Redirect::Inherit
      process = Process.new(@command, @args, input: input, output: output, error: error)
      status = process.wait
      unless status.success?
        raise Exception.new("command failed with status #{status.exit_code}: #{@command}")
      end
    rescue ex
      raise ex
    end
  end

  # ShellCommand runs a command via the system shell.
  class ShellCommand
    include ExecCommand

    @command : String
    @stdin : IO? = nil
    @stdout : IO? = nil
    @stderr : IO? = nil

    def initialize(@command : String)
    end

    # ameba:disable Naming/AccessorMethodName
    def set_stdin(reader : IO)
      @stdin ||= reader
    end

    # ameba:disable Naming/AccessorMethodName
    def set_stdout(writer : IO)
      @stdout ||= writer
    end

    # ameba:disable Naming/AccessorMethodName
    def set_stderr(writer : IO)
      @stderr ||= writer
    end

    # ameba:enable Naming/AccessorMethodName

    def run : Nil
      input = @stdin ? @stdin.not_nil! : Process::Redirect::Inherit
      output = @stdout ? @stdout.not_nil! : Process::Redirect::Inherit
      error = @stderr ? @stderr.not_nil! : Process::Redirect::Inherit
      process = Process.new(@command, shell: true, input: input, output: output, error: error)
      status = process.wait
      unless status.success?
        raise Exception.new("command failed with status #{status.exit_code}: #{@command}")
      end
    rescue ex
      raise ex
    end
  end

  # Println prints above the Program
  # Output persists across renders
  def self.println(*args) : Cmd
    content = args.join(" ")
    (->(captured : String) : Cmd { -> : Msg? { PrintLineMsg.new(captured) } }).call(content)
  end

  # Printf prints above the Program with format string
  def self.printf(template : String, *args) : Cmd
    content = template % args
    (->(captured : String) : Cmd { -> : Msg? { PrintLineMsg.new(captured) } }).call(content)
  end

  # PrintLineMsg is used internally for Println/Printf
  struct PrintLineMsg
    include Msg
    property content : String

    def initialize(@content : String)
    end
  end
end
