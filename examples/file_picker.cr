require "../src/bubbletea"

struct ClearErrorMsg
  include Tea::Msg
end

private def clear_error_after(duration : Time::Span) : Bubbletea::Cmd
  Bubbletea.tick(duration, ->(_t : Time) { ClearErrorMsg.new.as(Tea::Msg?) })
end

class FilePickerModel
  include Bubbletea::Model

  ALLOWED = {".mod", ".sum", ".go", ".txt", ".md"}
  @entries : Array(String)
  getter selected_file : String

  def initialize
    @current_directory = ENV["HOME"]? || Dir.current
    @entries = load_entries
    @index = 0
    @selected_file = ""
    @quitting = false
    @error = nil.as(String?)
  end

  def init : Bubbletea::Cmd?
    nil
  end

  def update(msg : Tea::Msg)
    case msg
    when Bubbletea::KeyPressMsg
      case msg.string_with_mods
      when "ctrl+c", "q"
        @quitting = true
        return {self, Bubbletea.quit}
      when "up", "k"
        @index -= 1
        @index = 0 if @index < 0
      when "down", "j"
        @index += 1
        @index = @entries.size - 1 if @index >= @entries.size
      when "enter"
        return {self, nil} if @entries.empty?

        path = File.join(@current_directory, @entries[@index])
        if File.directory?(path)
          @current_directory = path
          @entries = load_entries
          @index = 0
          @selected_file = ""
        elsif allowed_file?(path)
          @selected_file = path
          @error = nil
        else
          @error = "#{path} is not valid."
          @selected_file = ""
          return {self, clear_error_after(2.seconds)}
        end
      end
    when ClearErrorMsg
      @error = nil
    end

    {self, nil}
  end

  def view : Bubbletea::View
    return Bubbletea::View.new("") if @quitting

    s = String.build do |io|
      io << "\n  "
      if err = @error
        io << err
      elsif @selected_file.empty?
        io << "Pick a file:"
      else
        io << "Selected file: #{@selected_file}"
      end

      io << "\n\n"
      io << "Directory: #{@current_directory}\n"

      @entries.each_with_index do |entry, i|
        pointer = i == @index ? "> " : "  "
        io << pointer << entry << '\n'
      end

      io << "\nUse ↑/↓ (or j/k), Enter to open/select, q to quit."
    end

    v = Bubbletea::View.new(s)
    v.alt_screen = true
    v
  end

  private def load_entries : Array(String)
    entries = Dir.children(@current_directory)
      .select { |name| !name.starts_with?(".") }
      .sort

    if @current_directory != "/"
      entries.unshift("..")
    end

    entries
  rescue
    [".."]
  end

  private def allowed_file?(path : String) : Bool
    ext = File.extname(path)
    ALLOWED.includes?(ext)
  end
end

model = FilePickerModel.new
program = Bubbletea::Program.new(model)
final_model, err = program.run

if err
  STDERR.puts "Error: #{err.message}"
  exit 1
end

if fm = final_model.as?(FilePickerModel)
  puts "\n  You selected: #{fm.selected_file}\n"
end
