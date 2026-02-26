require "../src/bubbletea"

BANNED_TITLE_WORDS = {
  "very", "bad", "words", "that", "should", "not", "appear", "in", "book", "titles",
}

class IsbnFormModel
  include Bubbletea::Model

  def initialize
    @isbn = ""
    @title = ""
    @focused_input = 0
    @isbn_error = nil.as(String?)
    @title_error = nil.as(String?)
  end

  def init : Bubbletea::Cmd?
    Bubbletea.tick(500.milliseconds, ->(_t : Time) { Bubbletea["blink"].as(Tea::Msg?) })
  end

  def update(msg : Tea::Msg)
    case msg
    when Bubbletea::KeyPressMsg
      key = msg.string_with_mods
      case key
      when "up", "down"
        @focused_input = @focused_input == 0 ? 1 : 0
      when "enter"
        validate
        return {self, Bubbletea.quit} if can_find_book?
      when "ctrl+c", "esc"
        return {self, Bubbletea.quit}
      when "backspace"
        if @focused_input == 0
          @isbn = @isbn[0...-1] unless @isbn.empty?
        else
          @title = @title[0...-1] unless @title.empty?
        end
      when "space"
        @title += " " if @focused_input == 1
      else
        if rune = msg.rune
          if @focused_input == 0
            @isbn += rune.to_s
          else
            @title += rune.to_s
          end
        end
      end
      validate
    end

    {self, nil}
  end

  def view : Bubbletea::View
    continue_text = can_find_book? ? "Find ->" : ""

    s = String.build do |io|
      io << " Search book:\n"
      io << " ISBN\n"
      io << " " << focused_field(@isbn, 0) << "\n"
      io << " " << field_status(@isbn_error, @isbn, "Valid ISBN") << "\n\n"
      io << " Title\n"
      io << " " << focused_field(@title, 1) << "\n"
      io << " " << field_status(@title_error, @title, "Valid title") << "\n\n"
      io << " " << continue_text << "\n"
    end

    Bubbletea::View.new(s + "\n")
  end

  private def focused_field(value : String, idx : Int32) : String
    marker = @focused_input == idx ? ">" : " "
    "#{marker} #{value}"
  end

  private def field_status(err : String?, value : String, ok : String) : String
    return "" if value.empty?
    err || ok
  end

  private def can_find_book? : Bool
    validate
    @isbn_error.nil? && !@isbn.empty? && @title_error.nil? && !@title.empty?
  end

  private def validate
    @isbn_error = isbn13_validator(@isbn)
    @title_error = book_title_validator(@title)
  end

  private def isbn13_validator(s : String) : String?
    value = s.gsub("-", "")
    return "ISBN is of wrong length" unless value.size == 13
    return "ISBN contains invalid characters" unless value.chars.all?(&.ascii_number?)

    prefix = value[0, 3]
    return "ISBN has invalid GS1 prefix" unless prefix.in?({"978", "979"})

    sum = 0
    value.chars.each_with_index do |c, i|
      n = c.ord - '0'.ord
      n *= 3 if i.odd?
      sum += n
    end

    return "ISBN has invalid check digit" unless sum % 10 == 0
    nil
  end

  private def book_title_validator(s : String) : String?
    value = s.strip
    return "Book title is empty" if value.empty?

    down = value.downcase
    BANNED_TITLE_WORDS.each do |word|
      return %(Book title contains banned word "#{word}") if down.includes?(word)
    end

    nil
  end
end

program = Bubbletea::Program.new(IsbnFormModel.new)
_model, err = program.run
if err
  STDERR.puts err.message
  exit 1
end
