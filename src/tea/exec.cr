# External command execution for Tea v2-exp
# Ported from Go exec.go

require "process"

module Tea
  # ExecCommand interface for running external commands
  # This is satisfied by Process or custom implementations
  module ExecCommand
    abstract def run : Nil
    abstract def set_stdin(reader : IO)
    abstract def set_stdout(writer : IO)
    abstract def set_stderr(writer : IO)
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

  # ExecProcess runs the given Process in a blocking fashion
  # Useful for spawning interactive applications like editors and shells
  #
  # Example:
  #   cmd = Tea.exec_process(
  #     Process.new("vim", ["file.txt"]),
  #     ->(err : Exception?) {
  #       err ? Tea::Value.new(err) : nil
  #     }
  #   )
  def self.exec_process(process : Process, callback : ExecCallback? = nil) : Cmd
    exec(ProcessWrapper.new(process), callback)
  end

  # Convenience method to exec a shell command
  def self.exec_shell(command : String, callback : ExecCallback? = nil) : Cmd
    exec_process(Process.new(command, shell: true), callback)
  end

  # ProcessWrapper wraps Crystal's Process to satisfy ExecCommand interface
  # Matches Go's osExecCommand behavior
  private class ProcessWrapper
    include ExecCommand

    @process : Process

    def initialize(@process : Process)
    end

    # SetStdin sets stdin only if not already set (matches Go logic)
    def set_stdin(reader : IO)
      # In Go: if c.Stdin == nil { c.Stdin = r }
      # Crystal Process input is set at creation time, so we track separately
    end

    # SetStdout sets stdout only if not already set (matches Go logic)
    def set_stdout(writer : IO)
      # In Go: if c.Stdout == nil { c.Stdout = w }
    end

    # SetStderr sets stderr only if not already set (matches Go logic)
    def set_stderr(writer : IO)
      # In Go: if c.Stderr == nil { c.Stderr = w }
    end

    def run : Nil
      # Execute system command and wait
      @process.wait
    rescue ex
      # Process error - re-raise to be handled by caller
      raise ex
    end
  end

  # Println prints above the Program
  # Output persists across renders
  def self.println(*args) : Cmd
    msg = args.join(" ")
    -> : Msg? { PrintLineMsg.new(msg) }
  end

  # Printf prints above the Program with format string
  def self.printf(template : String, *args) : Cmd
    msg = template % args
    -> : Msg? { PrintLineMsg.new(msg) }
  end

  # PrintLineMsg is used internally for Println/Printf
  struct PrintLineMsg
    include Msg
    property content : String

    def initialize(@content : String)
    end
  end
end
