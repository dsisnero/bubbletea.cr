module Tea
  # ProgramStatus is a Program Status Protocol (OSC 7501) report. It tells the
  # terminal whether the program is idle, working, waiting on the user, done,
  # or failed, and why. Set it on `View#program_status`.
  #
  # Types and encoding come from the `ansi` shard. Support replies use the
  # typed `Ultraviolet::ProgramStatusSupportEvent` when the installed shard
  # provides it; tagged releases still need raw OSC parsing, so the fallback
  # below remains until a release ships the decoder
  # (see `shards_issues/ultraviolet.1.md`).
  #
  # See: https://www.superlogical.com/rex/docs/build/program-status
  alias ProgramStatus = Ansi::ProgramStatus

  # ProgramState is the state of a [ProgramStatus].
  alias ProgramState = Ansi::ProgramState

  # ProgramStatusKind says what a blocked program waits for.
  alias ProgramStatusKind = Ansi::ProgramStatusKind

  # Program states.
  ProgramStateIdle    = Ansi::ProgramState::Idle
  ProgramStateWorking = Ansi::ProgramState::Working
  ProgramStateDone    = Ansi::ProgramState::Done
  ProgramStateBlocked = Ansi::ProgramState::Blocked
  ProgramStateError   = Ansi::ProgramState::Error
  ProgramStateClear   = Ansi::ProgramState::Clear

  # Program status kinds.
  ProgramStatusKindPermission = Ansi::ProgramStatusKind::Permission
  ProgramStatusKindQuestion   = Ansi::ProgramStatusKind::Question
  ProgramStatusKindAuth       = Ansi::ProgramStatusKind::Auth

  # ProgramStatusSupportMsg is sent when the terminal replies to
  # `Tea.request_program_status_support`, meaning it supports the Program
  # Status Protocol.
  struct ProgramStatusSupportMsg
    include Msg
  end

  # ProgramStatusSupport detects the raw OSC 7501 support reply.
  #
  # Fallback for ultraviolet releases that predate the typed decoder event
  # (see `shards_issues/ultraviolet.1.md`).
  module ProgramStatusSupport
    # True when +sequence+ is an OSC 7501 support reply (`OSC 7501 ; ?`).
    def self.reply?(sequence : String) : Bool
      prefix = "\e]7501;"
      sequence.starts_with?(prefix) && sequence[prefix.size]? == '?'
    end
  end

  # RequestProgramStatusSupport asks the terminal whether it supports the
  # Program Status Protocol (OSC 7501). A supporting terminal replies with a
  # ProgramStatusSupportMsg. Terminals that don't support it never reply.
  #
  # The reply must be read from input, so this requires `with_input`.
  # Detection is optional: reports can be sent without it.
  def self.request_program_status_support : Cmd
    -> : Msg? { ProgramStatusSupportMsg.new }
  end
end
