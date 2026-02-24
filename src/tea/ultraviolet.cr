# Ultraviolet compatibility extensions for Tea v2-exp
# This adds Tea-specific helper methods for working with ultraviolet types

module Tea
  # KeyMod helpers for checking modifiers
  # Since Ultraviolet::KeyMod is just an Int32 alias, we provide helper methods
  module KeyModHelpers
    def self.shift?(mod : Ultraviolet::KeyMod) : Bool
      (mod & 1) != 0
    end

    def self.alt?(mod : Ultraviolet::KeyMod) : Bool
      (mod & 2) != 0
    end

    def self.ctrl?(mod : Ultraviolet::KeyMod) : Bool
      (mod & 4) != 0
    end

    def self.meta?(mod : Ultraviolet::KeyMod) : Bool
      (mod & 8) != 0
    end

    def self.hyper?(mod : Ultraviolet::KeyMod) : Bool
      (mod & 16) != 0
    end

    def self.super?(mod : Ultraviolet::KeyMod) : Bool
      (mod & 32) != 0
    end

    def self.caps_lock?(mod : Ultraviolet::KeyMod) : Bool
      (mod & 64) != 0
    end

    def self.num_lock?(mod : Ultraviolet::KeyMod) : Bool
      (mod & 128) != 0
    end

    def self.scroll_lock?(mod : Ultraviolet::KeyMod) : Bool
      (mod & 256) != 0
    end
  end

  # Extend Mouse struct to add modifier check methods
  struct Mouse
    def shift?
      KeyModHelpers.shift?(@modifiers)
    end

    def alt?
      KeyModHelpers.alt?(@modifiers)
    end

    def ctrl?
      KeyModHelpers.ctrl?(@modifiers)
    end

    def meta?
      KeyModHelpers.meta?(@modifiers)
    end
  end

  struct Key
    def shift?
      KeyModHelpers.shift?(@modifiers)
    end

    def alt?
      KeyModHelpers.alt?(@modifiers)
    end

    def ctrl?
      KeyModHelpers.ctrl?(@modifiers)
    end

    def meta?
      KeyModHelpers.meta?(@modifiers)
    end
  end
end
