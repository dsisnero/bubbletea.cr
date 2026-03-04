require "../lib/bubbles/src/bubbles"
require "lipgloss"

BANNED_TITLE_WORDS = ["very", "bad", "words", "that", "should", "not", "appear", "in", "book", "titles"]

INPUT_STYLE    = Lipgloss::Style.new.foreground("#FF9D00")
CONTINUE_STYLE = Lipgloss::Style.new.foreground("#D4A06A")
VALID_STYLE    = Lipgloss::Style.new.foreground("#6FBF73")
ERR_STYLE      = Lipgloss::Style.new.foreground("#E85D75")

class IsbnFormModel
  include Bubbletea::Model

  @isbn_input : Bubbles::TextInput::Model
  @title_input : Bubbles::TextInput::Model
  @focused_input : Int32
  @err : Exception?

  def initialize
    @isbn_input = Bubbles::TextInput.new
    @isbn_input.focus
    @isbn_input.placeholder = "978-X-XXX-XXXXX-X"
    @isbn_input.char_limit = 17
    @isbn_input.set_width(30)
    @isbn_input.prompt = ""
    @isbn_input.validate = ->(s : String) { isbn13_validator(s) }

    @title_input = Bubbles::TextInput.new
    @title_input.blur
    @title_input.placeholder = "Title"
    @title_input.char_limit = 100
    @title_input.set_width(100)
    @title_input.prompt = ""
    @title_input.validate = ->(s : String) { book_title_validator(s) }

    @focused_input = 0
    @err = nil
  end

  def can_find_book? : Bool
    correct_isbn_given = @isbn_input.err.nil? && @isbn_input.value.size != 0
    correct_title_given = @title_input.err.nil? && @title_input.value.size != 0
    correct_isbn_given && correct_title_given
  end

  def init : Bubbletea::Cmd?
    -> { Bubbles::TextInput.blink.as(Tea::Msg?) }
  end

  def update(msg : Tea::Msg)
    cmds = [] of Tea::Cmd?

    case msg
    when Tea::KeyPressMsg
      case msg.keystroke
      when "up", "down"
        case @focused_input
        when 0
          @focused_input = 1
          if cmd = @title_input.focus
            cmds << cmd
          end
          @isbn_input.blur
        when 1
          @focused_input = 0
          if cmd = @isbn_input.focus
            cmds << cmd
          end
          @title_input.blur
        end
      when "enter"
        return {self, Tea.quit} if can_find_book?
      when "ctrl+c", "esc"
        return {self, Tea.quit}
      end
    end

    @isbn_input, isbn_command = @isbn_input.update(msg)
    @title_input, title_command = @title_input.update(msg)
    cmds << isbn_command
    cmds << title_command

    {self, Tea.batch(cmds)}
  end

  def view : Bubbletea::View
    continue_text = can_find_book? ? CONTINUE_STYLE.render("Find ->") : ""

    isbn_error_text = ""
    if @isbn_input.value != ""
      if err = @isbn_input.err
        isbn_error_text = ERR_STYLE.render(err.message.to_s)
      else
        isbn_error_text = VALID_STYLE.render("Valid ISBN")
      end
    end

    title_error_text = ""
    if @title_input.value != ""
      if err = @title_input.err
        title_error_text = ERR_STYLE.render(err.message.to_s)
      else
        title_error_text = VALID_STYLE.render("Valid title")
      end
    end

    content = String.build do |io|
      io << " Search book:\n"
      io << " " << INPUT_STYLE.width(30).render("ISBN") << "\n"
      io << " " << @isbn_input.view << "\n"
      io << " " << isbn_error_text << "\n\n"
      io << " " << INPUT_STYLE.width(30).render("Title") << "\n"
      io << " " << @title_input.view << "\n"
      io << " " << title_error_text << "\n\n"
      io << " " << continue_text << "\n"
    end

    Bubbletea::View.new(content + "\n")
  end

  private def isbn13_validator(s : String) : Exception?
    value = s.gsub("-", "")
    return Exception.new("ISBN is of wrong length") unless value.size == 13
    return Exception.new("ISBN contains invalid characters") unless value.chars.all?(&.ascii_number?)

    gs1_prefix = value[0, 3]
    case gs1_prefix
    when "978", "979"
    else
      return Exception.new("ISBN has invalid GS1 prefix")
    end

    sum = 0
    value.each_char_with_index do |c, i|
      n = c.ord - '0'.ord
      n *= 3 if i.odd?
      sum += n
    end

    return Exception.new("ISBN has invalid check digit") unless sum % 10 == 0
    nil
  end

  private def book_title_validator(s : String) : Exception?
    value = s.strip
    return Exception.new("Book title is empty") if value.empty?

    BANNED_TITLE_WORDS.each do |word|
      return Exception.new(%(Book title contains banned word "#{word}")) if value.includes?(word)
    end

    nil
  end
end

unless ENV["BUBBLETEA_EXAMPLE_DISABLE_MAIN"]? == "1"
  unless STDIN.tty? && STDOUT.tty?
    STDERR.puts "Error running program: bubbletea: error opening TTY: stdin/stdout are not TTY"
    exit 1
  end
  program = Bubbletea::Program.new(IsbnFormModel.new)
  _model, err = program.run
  if err
    STDERR.puts err.message
    exit 1
  end
end
