require "bubbles"
require "lipgloss"

struct ClearErrorMsg
  include Tea::Msg
end

private def clear_error_after(duration : Time::Span) : Tea::Cmd
  Tea.tick(duration) { ClearErrorMsg.new }
end

class FilePickerModel
  include Tea::Model

  @filepicker : Bubbles::Filepicker::Model
  @selected_file : String
  @quitting : Bool
  @error : String?

  def initialize
    @filepicker = Bubbles::Filepicker.new
    @filepicker.allowed_types = [".mod", ".sum", ".go", ".txt", ".md"]
    @filepicker.current_directory = ENV["HOME"]? || Dir.current
    @filepicker.show_permissions = false
    @filepicker.show_size = false
    @selected_file = ""
    @quitting = false
    @error = nil
  end

  def init : Tea::Cmd?
    @filepicker.init
  end

  def update(msg : Tea::Msg)
    case msg
    when Tea::KeyPressMsg
      case msg.string
      when "ctrl+c", "q"
        @quitting = true
        return {self, Tea.quit}
      end
    when ClearErrorMsg
      @error = nil
    end

    # Update filepicker
    updated_picker, cmd = @filepicker.update(msg)
    @filepicker = updated_picker

    # Check if user selected a file
    did_select, path = @filepicker.did_select_file(msg)
    if did_select
      @selected_file = path
      @error = nil
    end

    # Check if user selected a disabled file
    did_select_disabled, disabled_path = @filepicker.did_select_disabled_file(msg)
    if did_select_disabled
      @error = "#{disabled_path} is not valid."
      @selected_file = ""
      return {self, Tea.batch(cmd, clear_error_after(2.seconds))}
    end

    {self, cmd}
  end

  def view : Tea::View
    if @quitting
      return Tea.new_view("")
    end

    s = String.build do |io|
      io << "\n  "
      if err = @error
        io << @filepicker.styles.disabled_file.render(err)
      elsif @selected_file.empty?
        io << "Pick a file:"
      else
        io << "Selected file: " << @filepicker.styles.selected.render(@selected_file)
      end
      io << "\n\n"
      io << @filepicker.view
    end

    v = Tea.new_view(s)
    v.alt_screen = true
    v
  end
end

model = FilePickerModel.new
program = Tea::Program.new(model)
final_model, err = program.run

if err
  STDERR.puts "Error: #{err.message}"
  exit 1
end

if fm = final_model.as?(FilePickerModel)
  puts "\n  You selected: " + fm.@filepicker.styles.selected.render(fm.@selected_file) + "\n"
end
