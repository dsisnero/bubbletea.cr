ENV["BUBBLETEA_EXAMPLE_DISABLE_MAIN"] = "1"
require "../../../examples/table_resize"

out_path = ENV["CR_CAPTURE_OUT"]?
raise "CR_CAPTURE_OUT is required" if out_path.nil? || out_path.empty?

output = IO::Memory.new
program = Bubbletea.new_program(
  TableResizeModel.new,
  Tea.with_input(nil),
  Tea.with_output(output),
  Tea.without_signals,
  Tea.with_window_size(80, 24),
)

spawn do
  sleep 120.milliseconds
  program.send(Tea.key('q'))
end

_model, err = program.run
raise err.not_nil! if err

File.open(out_path, "wb") { |f| f.write(output.to_slice) }
