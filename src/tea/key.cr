# Keyboard handling for Tea v2-exp
# In Go: KeyMod = uv.KeyMod, Key constants from uv package

module Tea
  # KeyMod is an alias for Ultraviolet::KeyMod
  alias KeyMod = Ultraviolet::KeyMod

  # Go parity key code constants re-exported from Ultraviolet.
  KeyExtended = Ultraviolet::KeyExtended

  KeyUp     = Ultraviolet::KeyUp
  KeyDown   = Ultraviolet::KeyDown
  KeyRight  = Ultraviolet::KeyRight
  KeyLeft   = Ultraviolet::KeyLeft
  KeyBegin  = Ultraviolet::KeyBegin
  KeyFind   = Ultraviolet::KeyFind
  KeyInsert = Ultraviolet::KeyInsert
  KeyDelete = Ultraviolet::KeyDelete
  KeySelect = Ultraviolet::KeySelect
  KeyPgUp   = Ultraviolet::KeyPgUp
  KeyPgDown = Ultraviolet::KeyPgDown
  KeyHome   = Ultraviolet::KeyHome
  KeyEnd    = Ultraviolet::KeyEnd

  KeyKpEnter    = Ultraviolet::KeyKpEnter
  KeyKpEqual    = Ultraviolet::KeyKpEqual
  KeyKpMultiply = Ultraviolet::KeyKpMultiply
  KeyKpPlus     = Ultraviolet::KeyKpPlus
  KeyKpComma    = Ultraviolet::KeyKpComma
  KeyKpMinus    = Ultraviolet::KeyKpMinus
  KeyKpDecimal  = Ultraviolet::KeyKpDecimal
  KeyKpDivide   = Ultraviolet::KeyKpDivide
  KeyKp0        = Ultraviolet::KeyKp0
  KeyKp1        = Ultraviolet::KeyKp1
  KeyKp2        = Ultraviolet::KeyKp2
  KeyKp3        = Ultraviolet::KeyKp3
  KeyKp4        = Ultraviolet::KeyKp4
  KeyKp5        = Ultraviolet::KeyKp5
  KeyKp6        = Ultraviolet::KeyKp6
  KeyKp7        = Ultraviolet::KeyKp7
  KeyKp8        = Ultraviolet::KeyKp8
  KeyKp9        = Ultraviolet::KeyKp9
  KeyKpSep      = Ultraviolet::KeyKpSep
  KeyKpUp       = Ultraviolet::KeyKpUp
  KeyKpDown     = Ultraviolet::KeyKpDown
  KeyKpLeft     = Ultraviolet::KeyKpLeft
  KeyKpRight    = Ultraviolet::KeyKpRight
  KeyKpPgUp     = Ultraviolet::KeyKpPgUp
  KeyKpPgDown   = Ultraviolet::KeyKpPgDown
  KeyKpHome     = Ultraviolet::KeyKpHome
  KeyKpEnd      = Ultraviolet::KeyKpEnd
  KeyKpInsert   = Ultraviolet::KeyKpInsert
  KeyKpDelete   = Ultraviolet::KeyKpDelete
  KeyKpBegin    = Ultraviolet::KeyKpBegin

  KeyF1  = Ultraviolet::KeyF1
  KeyF2  = Ultraviolet::KeyF2
  KeyF3  = Ultraviolet::KeyF3
  KeyF4  = Ultraviolet::KeyF4
  KeyF5  = Ultraviolet::KeyF5
  KeyF6  = Ultraviolet::KeyF6
  KeyF7  = Ultraviolet::KeyF7
  KeyF8  = Ultraviolet::KeyF8
  KeyF9  = Ultraviolet::KeyF9
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

  KeyCapsLock    = Ultraviolet::KeyCapsLock
  KeyScrollLock  = Ultraviolet::KeyScrollLock
  KeyNumLock     = Ultraviolet::KeyNumLock
  KeyPrintScreen = Ultraviolet::KeyPrintScreen
  KeyPause       = Ultraviolet::KeyPause
  KeyMenu        = Ultraviolet::KeyMenu

  KeyMediaPlay        = Ultraviolet::KeyMediaPlay
  KeyMediaPause       = Ultraviolet::KeyMediaPause
  KeyMediaPlayPause   = Ultraviolet::KeyMediaPlayPause
  KeyMediaReverse     = Ultraviolet::KeyMediaReverse
  KeyMediaStop        = Ultraviolet::KeyMediaStop
  KeyMediaFastForward = Ultraviolet::KeyMediaFastForward
  KeyMediaRewind      = Ultraviolet::KeyMediaRewind
  KeyMediaNext        = Ultraviolet::KeyMediaNext
  KeyMediaPrev        = Ultraviolet::KeyMediaPrev
  KeyMediaRecord      = Ultraviolet::KeyMediaRecord

  KeyLowerVol = Ultraviolet::KeyLowerVol
  KeyRaiseVol = Ultraviolet::KeyRaiseVol
  KeyMute     = Ultraviolet::KeyMute

  KeyLeftShift      = Ultraviolet::KeyLeftShift
  KeyLeftAlt        = Ultraviolet::KeyLeftAlt
  KeyLeftCtrl       = Ultraviolet::KeyLeftCtrl
  KeyLeftSuper      = Ultraviolet::KeyLeftSuper
  KeyLeftHyper      = Ultraviolet::KeyLeftHyper
  KeyLeftMeta       = Ultraviolet::KeyLeftMeta
  KeyRightShift     = Ultraviolet::KeyRightShift
  KeyRightAlt       = Ultraviolet::KeyRightAlt
  KeyRightCtrl      = Ultraviolet::KeyRightCtrl
  KeyRightSuper     = Ultraviolet::KeyRightSuper
  KeyRightHyper     = Ultraviolet::KeyRightHyper
  KeyRightMeta      = Ultraviolet::KeyRightMeta
  KeyIsoLevel3Shift = Ultraviolet::KeyIsoLevel3Shift
  KeyIsoLevel5Shift = Ultraviolet::KeyIsoLevel5Shift

  KeyBackspace = Ultraviolet::KeyBackspace
  KeyTab       = Ultraviolet::KeyTab
  KeyEnter     = Ultraviolet::KeyEnter
  KeyReturn    = Ultraviolet::KeyReturn
  KeyEscape    = Ultraviolet::KeyEscape
  KeyEsc       = Ultraviolet::KeyEsc
  KeySpace     = Ultraviolet::KeySpace

  # Key represents a keyboard key
  struct Key
    include Msg

    # Text contains the actual characters received. This usually the same as
    # Code. When Text is non-empty, it indicates that the key pressed represents
    # printable character(s).
    property text : String

    # Mod represents modifier keys, like ModCtrl, ModAlt, and so on.
    property mod : KeyMod

    # Code represents the key pressed. This is usually a special key like
    # KeyTab, KeyEnter, KeyF1, or a printable character like 'a'.
    property code : Int32

    # ShiftedCode is the actual, shifted key pressed by the user.
    property shifted_code : Int32

    # BaseCode is the key pressed according to the standard PC-101 key layout.
    property base_code : Int32

    # IsRepeat indicates whether the key is being held down and sending events
    # repeatedly.
    property? is_repeat : Bool = false

    def initialize(
      @text : String = "",
      @mod : KeyMod = 0,
      @code : Int32 = 0,
      @shifted_code : Int32 = 0,
      @base_code : Int32 = 0,
      @is_repeat : Bool = false,
    )
    end

    # Check if this is a printable character
    def printable?
      !@text.empty?
    end

    # Get the string representation
    def to_s : String
      string
    end

    # Go parity helper for Key.String().
    def string : String
      if !@text.empty?
        @text
      else
        keystroke
      end
    end

    # Go parity helper for Key.Keystroke().
    def keystroke : String
      # Delegate to Ultraviolet for keystroke representation
      Ultraviolet::Key.new(@text, @mod, @code, @shifted_code, @base_code, @is_repeat).keystroke
    end
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

  # Helper to create a Key from a rune
  def self.key(rune : Char, modifiers : KeyMod = 0) : Key
    Key.new(rune.to_s, modifiers, rune.ord)
  end

  # Helper to create a Key from a special key type
  def self.key(code : Int32, modifiers : KeyMod = 0) : Key
    Key.new("", modifiers, code)
  end
end
