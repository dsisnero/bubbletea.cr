# Keyboard handling for Tea v2-exp
# In Go: KeyMod = uv.KeyMod, Key constants from uv package

module Tea
  # KeyMod is an alias for UVKeyMod (from ultraviolet)
  alias KeyMod = UVKeyMod

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
      @modifiers : KeyMod = UVKeyMod::None,
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
      @rune.to_s
    end

    # String with modifiers applied (e.g., "ctrl+c")
    def string_with_mods : String
      parts = [] of String
      parts << "ctrl" if @modifiers.ctrl?
      parts << "alt" if @modifiers.alt?
      parts << "shift" if @modifiers.shift?
      parts << "meta" if @modifiers.meta?

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
  def self.key(rune : Char, modifiers : KeyMod = UVKeyMod::None) : Key
    Key.new(KeyType::Null, rune, modifiers)
  end

  # Helper to create a Key from a special key type
  def self.key(type : KeyType, modifiers : KeyMod = UVKeyMod::None) : Key
    Key.new(type, nil, modifiers)
  end
end
