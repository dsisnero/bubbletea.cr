ENV["BUBBLETEA_EXAMPLE_DISABLE_MAIN"] = "1"
require "../../../examples/list_fancy"

out_path = ENV["CR_CAPTURE_OUT"]?
raise "CR_CAPTURE_OUT is required" if out_path.nil? || out_path.empty?

output = IO::Memory.new
RandomFancyItemGenerator.seed(1_i64)
program = Bubbletea.new_program(
  ListFancyModel.new,
  Tea.with_input(IO::Memory.new("")),
  Tea.with_output(output),
  Tea.without_signals,
  Tea.with_window_size(80, 24),
)

spawn do
  sleep 120.milliseconds
  program.send(Tea.key('H'))
  sleep 40.milliseconds
  program.send(Tea.key('a'))
  sleep 40.milliseconds
  program.send(Tea.key('q'))
end

_model, err = program.run
raise err.not_nil! if err

File.open(out_path, "wb") { |f| f.write(output.to_slice) }
