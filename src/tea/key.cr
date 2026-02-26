# Keyboard handling for Tea v2-exp
# In Go: KeyMod = uv.KeyMod, Key constants from uv package

module Tea
  # KeyMod is an alias for Ultraviolet::KeyMod
  alias KeyMod = Ultraviolet::KeyMod

  # Go parity key code constants re-exported from Ultraviolet.
  KeyExtended = Ultraviolet::KeyExtended

  KeyUp = Ultraviolet::KeyUp
  KeyDown = Ultraviolet::KeyDown
  KeyRight = Ultraviolet::KeyRight
  KeyLeft = Ultraviolet::KeyLeft
  KeyBegin = Ultraviolet::KeyBegin
  KeyFind = Ultraviolet::KeyFind
  KeyInsert = Ultraviolet::KeyInsert
  KeyDelete = Ultraviolet::KeyDelete
  KeySelect = Ultraviolet::KeySelect
  KeyPgUp = Ultraviolet::KeyPgUp
  KeyPgDown = Ultraviolet::KeyPgDown
  KeyHome = Ultraviolet::KeyHome
  KeyEnd = Ultraviolet::KeyEnd

  KeyKpEnter = Ultraviolet::KeyKpEnter
  KeyKpEqual = Ultraviolet::KeyKpEqual
  KeyKpMultiply = Ultraviolet::KeyKpMultiply
  KeyKpPlus = Ultraviolet::KeyKpPlus
  KeyKpComma = Ultraviolet::KeyKpComma
  KeyKpMinus = Ultraviolet::KeyKpMinus
  KeyKpDecimal = Ultraviolet::KeyKpDecimal
  KeyKpDivide = Ultraviolet::KeyKpDivide
  KeyKp0 = Ultraviolet::KeyKp0
  KeyKp1 = Ultraviolet::KeyKp1
  KeyKp2 = Ultraviolet::KeyKp2
  KeyKp3 = Ultraviolet::KeyKp3
  KeyKp4 = Ultraviolet::KeyKp4
  KeyKp5 = Ultraviolet::KeyKp5
  KeyKp6 = Ultraviolet::KeyKp6
  KeyKp7 = Ultraviolet::KeyKp7
  KeyKp8 = Ultraviolet::KeyKp8
  KeyKp9 = Ultraviolet::KeyKp9
  KeyKpSep = Ultraviolet::KeyKpSep
  KeyKpUp = Ultraviolet::KeyKpUp
  KeyKpDown = Ultraviolet::KeyKpDown
  KeyKpLeft = Ultraviolet::KeyKpLeft
  KeyKpRight = Ultraviolet::KeyKpRight
  KeyKpPgUp = Ultraviolet::KeyKpPgUp
  KeyKpPgDown = Ultraviolet::KeyKpPgDown
  KeyKpHome = Ultraviolet::KeyKpHome
  KeyKpEnd = Ultraviolet::KeyKpEnd
  KeyKpInsert = Ultraviolet::KeyKpInsert
  KeyKpDelete = Ultraviolet::KeyKpDelete
  KeyKpBegin = Ultraviolet::KeyKpBegin

  KeyF1 = Ultraviolet::KeyF1
  KeyF2 = Ultraviolet::KeyF2
  KeyF3 = Ultraviolet::KeyF3
  KeyF4 = Ultraviolet::KeyF4
  KeyF5 = Ultraviolet::KeyF5
  KeyF6 = Ultraviolet::KeyF6
  KeyF7 = Ultraviolet::KeyF7
  KeyF8 = Ultraviolet::KeyF8
  KeyF9 = Ultraviolet::KeyF9
  KeyF10 = Ultraviolet::KeyF10
  KeyF11 = Ultraviolet::KeyF11
  KeyF12 = Ultraviolet::KeyF12
  KeyF13 = Ultraviolet::KeyF13
  KeyF14 = Ultraviolet::KeyF14
  KeyF15 = Ultraviolet::KeyF15
  KeyF16 = Ultraviolet::KeyF16
  KeyF17 = Ultraviolet::KeyF17
  KeyF18 = Ultraviolet::KeyF18
  KeyF19 = Ultraviolet::KeyF19
  KeyF20 = Ultraviolet::KeyF20
  KeyF21 = Ultraviolet::KeyF21
  KeyF22 = Ultraviolet::KeyF22
  KeyF23 = Ultraviolet::KeyF23
  KeyF24 = Ultraviolet::KeyF24
  KeyF25 = Ultraviolet::KeyF25
  KeyF26 = Ultraviolet::KeyF26
  KeyF27 = Ultraviolet::KeyF27
  KeyF28 = Ultraviolet::KeyF28
  KeyF29 = Ultraviolet::KeyF29
  KeyF30 = Ultraviolet::KeyF30
  KeyF31 = Ultraviolet::KeyF31
  KeyF32 = Ultraviolet::KeyF32
  KeyF33 = Ultraviolet::KeyF33
  KeyF34 = Ultraviolet::KeyF34
  KeyF35 = Ultraviolet::KeyF35
  KeyF36 = Ultraviolet::KeyF36
  KeyF37 = Ultraviolet::KeyF37
  KeyF38 = Ultraviolet::KeyF38
  KeyF39 = Ultraviolet::KeyF39
  KeyF40 = Ultraviolet::KeyF40
  KeyF41 = Ultraviolet::KeyF41
  KeyF42 = Ultraviolet::KeyF42
  KeyF43 = Ultraviolet::KeyF43
  KeyF44 = Ultraviolet::KeyF44
  KeyF45 = Ultraviolet::KeyF45
  KeyF46 = Ultraviolet::KeyF46
  KeyF47 = Ultraviolet::KeyF47
  KeyF48 = Ultraviolet::KeyF48
  KeyF49 = Ultraviolet::KeyF49
  KeyF50 = Ultraviolet::KeyF50
  KeyF51 = Ultraviolet::KeyF51
  KeyF52 = Ultraviolet::KeyF52
  KeyF53 = Ultraviolet::KeyF53
  KeyF54 = Ultraviolet::KeyF54
  KeyF55 = Ultraviolet::KeyF55
  KeyF56 = Ultraviolet::KeyF56
  KeyF57 = Ultraviolet::KeyF57
  KeyF58 = Ultraviolet::KeyF58
  KeyF59 = Ultraviolet::KeyF59
  KeyF60 = Ultraviolet::KeyF60
  KeyF61 = Ultraviolet::KeyF61
  KeyF62 = Ultraviolet::KeyF62
  KeyF63 = Ultraviolet::KeyF63

  KeyCapsLock = Ultraviolet::KeyCapsLock
  KeyScrollLock = Ultraviolet::KeyScrollLock
  KeyNumLock = Ultraviolet::KeyNumLock
  KeyPrintScreen = Ultraviolet::KeyPrintScreen
  KeyPause = Ultraviolet::KeyPause
  KeyMenu = Ultraviolet::KeyMenu

  KeyMediaPlay = Ultraviolet::KeyMediaPlay
  KeyMediaPause = Ultraviolet::KeyMediaPause
  KeyMediaPlayPause = Ultraviolet::KeyMediaPlayPause
  KeyMediaReverse = Ultraviolet::KeyMediaReverse
  KeyMediaStop = Ultraviolet::KeyMediaStop
  KeyMediaFastForward = Ultraviolet::KeyMediaFastForward
  KeyMediaRewind = Ultraviolet::KeyMediaRewind
  KeyMediaNext = Ultraviolet::KeyMediaNext
  KeyMediaPrev = Ultraviolet::KeyMediaPrev
  KeyMediaRecord = Ultraviolet::KeyMediaRecord

  KeyLowerVol = Ultraviolet::KeyLowerVol
  KeyRaiseVol = Ultraviolet::KeyRaiseVol
  KeyMute = Ultraviolet::KeyMute

  KeyLeftShift = Ultraviolet::KeyLeftShift
  KeyLeftAlt = Ultraviolet::KeyLeftAlt
  KeyLeftCtrl = Ultraviolet::KeyLeftCtrl
  KeyLeftSuper = Ultraviolet::KeyLeftSuper
  KeyLeftHyper = Ultraviolet::KeyLeftHyper
  KeyLeftMeta = Ultraviolet::KeyLeftMeta
  KeyRightShift = Ultraviolet::KeyRightShift
  KeyRightAlt = Ultraviolet::KeyRightAlt
  KeyRightCtrl = Ultraviolet::KeyRightCtrl
  KeyRightSuper = Ultraviolet::KeyRightSuper
  KeyRightHyper = Ultraviolet::KeyRightHyper
  KeyRightMeta = Ultraviolet::KeyRightMeta
  KeyIsoLevel3Shift = Ultraviolet::KeyIsoLevel3Shift
  KeyIsoLevel5Shift = Ultraviolet::KeyIsoLevel5Shift

  KeyBackspace = Ultraviolet::KeyBackspace
  KeyTab = Ultraviolet::KeyTab
  KeyEnter = Ultraviolet::KeyEnter
  KeyReturn = Ultraviolet::KeyReturn
  KeyEscape = Ultraviolet::KeyEscape
  KeyEsc = Ultraviolet::KeyEsc
  KeySpace = Ultraviolet::KeySpace

  # Key represents a keyboard key
  struct Key
    include Msg

    # The key type (runes for printable keys, special values for special keys)
    property type : KeyType

    # The rune for printable keys
    property rune : Char?

    # Modifier keys that were pressed
    property modifiers : KeyMod

    # Whether this is a repeated key press
    property? is_repeat : Bool = false

    # For special keys that have alternate representations
    property alternate : KeyType?

    def initialize(
      @type : KeyType,
      @rune : Char? = nil,
      @modifiers : KeyMod = Ultraviolet::KeyMod::None,
      @is_repeat : Bool = false,
      @alternate : KeyType? = nil,
    )
    end

    # Check if this is a printable character
    def printable?
      @rune && @rune != ' '
    end

    # Get the string representation
    def to_s : String
      string
    end

    # Go parity helper for Key.String().
    def string : String
      if @rune
        @rune.to_s
      else
        keystroke
      end
    end

    # Go parity helper for Key.Keystroke().
    def keystroke : String
      string_with_mods
    end

    # String with modifiers applied (e.g., "ctrl+c")
    def string_with_mods : String
      parts = [] of String
      parts << "ctrl" if KeyModHelpers.ctrl?(@modifiers)
      parts << "alt" if KeyModHelpers.alt?(@modifiers)
      parts << "shift" if KeyModHelpers.shift?(@modifiers)
      parts << "meta" if KeyModHelpers.meta?(@modifiers)

      key_str = @type.to_s.downcase
      parts << key_str

      parts.join("+")
    end
  end

  # KeyType represents the type of key
  enum KeyType
    # Special keys
    Null
    Break
    Enter
    Backspace
    Tab
    Escape
    Space
    Up
    Down
    Left
    Right
    Home
    End
    PageUp
    PageDown
    Delete
    Insert
    F1
    F2
    F3
    F4
    F5
    F6
    F7
    F8
    F9
    F10
    F11
    F12
    F13
    F14
    F15
    F16
    F17
    F18
    F19
    F20
    F21
    F22
    F23
    F24
    F25
    F26
    F27
    F28
    F29
    F30
    F31
    F32
    F33
    F34
    F35
    # Runes for printable characters are stored as their integer value
  end

  # KeyPressMsg is sent when a key is pressed
  alias KeyPressMsg = Key

  # KeyReleaseMsg is sent when a key is released
  struct KeyReleaseMsg
    include Msg
    property key : Key

    def initialize(@key : Key)
    end

    # Go parity helper for KeyReleaseMsg.String().
    def string : String
      key.string
    end

    # Go parity helper for KeyReleaseMsg.Keystroke().
    def keystroke : String
      key.keystroke
    end
  end

  # KeyMsg is the interface for all keyboard messages
  module KeyMsg
    include Msg

    abstract def key : Key
  end

  # KeyNames maps key types to their string names
  KEY_NAMES = {
    KeyType::Null      => "null",
    KeyType::Break     => "break",
    KeyType::Enter     => "enter",
    KeyType::Backspace => "backspace",
    KeyType::Tab       => "tab",
    KeyType::Escape    => "esc",
    KeyType::Space     => "space",
    KeyType::Up        => "up",
    KeyType::Down      => "down",
    KeyType::Left      => "left",
    KeyType::Right     => "right",
    KeyType::Home      => "home",
    KeyType::End       => "end",
    KeyType::PageUp    => "pgup",
    KeyType::PageDown  => "pgdown",
    KeyType::Delete    => "delete",
    KeyType::Insert    => "insert",
    KeyType::F1        => "f1",
    KeyType::F2        => "f2",
    KeyType::F3        => "f3",
    KeyType::F4        => "f4",
    KeyType::F5        => "f5",
    KeyType::F6        => "f6",
    KeyType::F7        => "f7",
    KeyType::F8        => "f8",
    KeyType::F9        => "f9",
    KeyType::F10       => "f10",
    KeyType::F11       => "f11",
    KeyType::F12       => "f12",
    KeyType::F13       => "f13",
    KeyType::F14       => "f14",
    KeyType::F15       => "f15",
    KeyType::F16       => "f16",
    KeyType::F17       => "f17",
    KeyType::F18       => "f18",
    KeyType::F19       => "f19",
    KeyType::F20       => "f20",
    KeyType::F21       => "f21",
    KeyType::F22       => "f22",
    KeyType::F23       => "f23",
    KeyType::F24       => "f24",
    KeyType::F25       => "f25",
    KeyType::F26       => "f26",
    KeyType::F27       => "f27",
    KeyType::F28       => "f28",
    KeyType::F29       => "f29",
    KeyType::F30       => "f30",
    KeyType::F31       => "f31",
    KeyType::F32       => "f32",
    KeyType::F33       => "f33",
    KeyType::F34       => "f34",
    KeyType::F35       => "f35",
  }

  # Helper to create a Key from a rune
  def self.key(rune : Char, modifiers : KeyMod = Ultraviolet::KeyMod::None) : Key
    Key.new(KeyType::Null, rune, modifiers)
  end

  # Helper to create a Key from a special key type
  def self.key(type : KeyType, modifiers : KeyMod = Ultraviolet::KeyMod::None) : Key
    Key.new(type, nil, modifiers)
  end
end
