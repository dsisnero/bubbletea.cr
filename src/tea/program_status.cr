require "base64"

module Tea
  # ProgramState is the state of a program reported with the Program Status
  # Protocol (OSC 7501).
  #
  # See: https://www.superlogical.com/rex/docs/build/program-status
  enum ProgramState
    Idle
    Working
    Done
    Blocked
    Error
    Clear

    # Wire value used in OSC 7501 reports.
    def wire_name : String
      to_s.downcase
    end
  end

  # ProgramStatusKind says what a blocked program is waiting for.
  enum ProgramStatusKind
    Permission
    Question
    Auth

    # Wire value used in OSC 7501 reports.
    def wire_name : String
      to_s.downcase
    end
  end

  # ProgramStatus is a Program Status Protocol (OSC 7501) report. It tells the
  # terminal whether the program is idle, working, waiting on the user, done,
  # or failed, and why. Set it on `View#program_status`.
  #
  # Each report replaces its record completely, so fields such as `app` and
  # `title` should be included in every report.
  #
  # See: https://www.superlogical.com/rex/docs/build/program-status
  struct ProgramStatus
    # State is the program state. Required.
    property state : ProgramState

    # ID addresses a record. Empty means the root record. It is a "/" separated
    # path of segments matching [A-Za-z0-9_.+-]{1,32}.
    property id : String

    # App is a stable machine-readable program name.
    property app : String

    # Kind says what a blocked program waits for.
    property kind : ProgramStatusKind?

    # Progress is a percentage between 0 and 100.
    property progress : Int32

    # HasProgress reports whether Progress is set.
    property? has_progress : Bool

    # Title is a short human-readable label for the record.
    property title : String

    # Message is one human-readable line describing the record.
    property message : String

    def initialize(
      @state : ProgramState,
      @id : String = "",
      @app : String = "",
      @kind : ProgramStatusKind? = nil,
      @progress : Int32 = 0,
      @has_progress : Bool = false,
      @title : String = "",
      @message : String = "",
    )
    end
  end

  # Program states (Go parity constants).
  ProgramStateIdle    = ProgramState::Idle
  ProgramStateWorking = ProgramState::Working
  ProgramStateDone    = ProgramState::Done
  ProgramStateBlocked = ProgramState::Blocked
  ProgramStateError   = ProgramState::Error
  ProgramStateClear   = ProgramState::Clear

  # Program status kinds (Go parity constants).
  ProgramStatusKindPermission = ProgramStatusKind::Permission
  ProgramStatusKindQuestion   = ProgramStatusKind::Question
  ProgramStatusKindAuth       = ProgramStatusKind::Auth

  # ProgramStatusSupportMsg is sent when the terminal replies to
  # `Tea.request_program_status_support`, meaning it supports the Program
  # Status Protocol.
  struct ProgramStatusSupportMsg
    include Msg
  end

  # ProgramStatusProtocol implements OSC 7501 encoding.
  #
  # The `ansi` and `ultraviolet` shards pinned by this port do not implement
  # the protocol yet; see `shards_issues/ansi.1.md` and
  # `shards_issues/ultraviolet.1.md`. Move this to the shards when they do.
  module ProgramStatusProtocol
    CLEAR           = "\e]7501;state=clear\a"
    REQUEST_SUPPORT = "\e]7501;?\a"

    MAX_TITLE    =  192
    MAX_MESSAGE  = 2048
    MAX_ID       =  128
    MAX_SEGMENTS =    8
    MAX_SEGMENT  =   32

    # Returns the OSC 7501 report for +status+, or an empty string when the
    # record id is invalid (terminals discard invalid reports).
    def self.set(status : ProgramStatus) : String
      return "" unless valid_id?(status.id)

      pairs = ["state=#{status.state.wire_name}"]
      pairs << "id=#{status.id}" unless status.id.empty?
      return sequence(pairs) if status.state.clear?

      if status.state.blocked? && (kind = status.kind)
        pairs << "kind=#{kind.wire_name}"
      end
      if status.has_progress? && (status.state.working? || status.state.blocked?)
        pairs << "progress=#{status.progress.clamp(0, 100)}"
      end
      pairs << "app=#{status.app}" if valid_segment?(status.app)
      if title = encode_text(status.title, MAX_TITLE)
        pairs << "title=#{title}"
      end
      if message = encode_text(status.message, MAX_MESSAGE)
        pairs << "msg=#{message}"
      end

      sequence(pairs)
    end

    # Removes the record with the given id and every record beneath it.
    # An empty id removes every record.
    def self.clear_id(id : String) : String
      set(ProgramStatus.new(state: ProgramState::Clear, id: id))
    end

    # True when +sequence+ is an OSC 7501 support reply (`OSC 7501 ; ?`).
    def self.support_reply?(sequence : String) : Bool
      prefix = "\e]7501;"
      sequence.starts_with?(prefix) && sequence[prefix.size]? == '?'
    end

    private def self.sequence(pairs : Array(String)) : String
      "\e]7501;#{pairs.join(":")}\a"
    end

    private def self.valid_id?(id : String) : Bool
      return true if id.empty?
      return false if id.bytesize > MAX_ID

      segments = id.split('/')
      return false if segments.size > MAX_SEGMENTS

      segments.all? { |segment| valid_segment?(segment) }
    end

    private def self.valid_segment?(segment : String) : Bool
      return false unless 1 <= segment.bytesize <= MAX_SEGMENT

      segment.each_byte.all? do |byte|
        (byte >= 0x61 && byte <= 0x7a) ||   # a-z
          (byte >= 0x41 && byte <= 0x5a) || # A-Z
          (byte >= 0x30 && byte <= 0x39) || # 0-9
          byte == 0x5f || byte == 0x2e || byte == 0x2b || byte == 0x2d
      end
    end

    # Sanitizes free text, truncates on a UTF-8 boundary, then base64-encodes
    # it as the protocol requires. Returns nil when nothing is left.
    private def self.encode_text(text : String, limit : Int32) : String?
      cleaned = String.build do |io|
        space = false
        text.each_char do |char|
          code = char.ord
          if code < 0x20 || (0x7f <= code <= 0x9f)
            unless space
              io << ' '
              space = true
            end
            next
          end
          space = false
          io << char
        end
      end

      cleaned = cleaned.strip
      return nil if cleaned.empty?

      if cleaned.bytesize > limit
        cleaned = cleaned.byte_slice(0, limit)
        while cleaned.bytesize > 0 && !cleaned.valid_encoding?
          cleaned = cleaned.byte_slice(0, cleaned.bytesize - 1)
        end
        cleaned = cleaned.strip
      end

      return nil if cleaned.empty?

      Base64.strict_encode(cleaned)
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
