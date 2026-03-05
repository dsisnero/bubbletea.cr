require "../spec_helper"
ENV["BUBBLETEA_EXAMPLE_DISABLE_MAIN"] = "1"
require "../../examples/query_term"

private def env_from_query_term_golden(golden : String) : Ultraviolet::Environ
  marker = "Received message: tea.EnvMsg ["
  marker_idx = golden.index(marker)
  return Ultraviolet::Environ.new([] of String) unless marker_idx

  env_start = marker_idx + marker.bytesize
  env_end = golden.index("]\e[K", env_start)
  return Ultraviolet::Environ.new([] of String) unless env_end

  payload = golden[env_start...env_end]
  starts = [] of Int32
  i = 0
  while i < payload.bytesize
    first = payload.byte_at(i)
    prefix_ok = i == 0 || payload.byte_at(i - 1) == ' '.ord
    start_ok = first.unsafe_chr.ascii_letter? || first == '_'.ord
    if prefix_ok && start_ok
      j = i + 1
      while j < payload.bytesize
        c = payload.byte_at(j)
        break unless c.unsafe_chr.ascii_letter? || c.unsafe_chr.number? || c == '_'.ord
        j += 1
      end
      if j < payload.bytesize && payload.byte_at(j) == '='.ord
        starts << i.to_i32
      end
    end
    i += 1
  end

  items = [] of String
  starts.each_with_index do |start_idx, idx|
    finish = (idx + 1 < starts.size) ? starts[idx + 1] - 1 : payload.bytesize
    entry = payload.byte_slice(start_idx, finish - start_idx).strip
    items << entry unless entry.empty?
  end
  Ultraviolet::Environ.new(items)
end

private def capture_query_term_output : Bytes
  golden = File.read("#{__DIR__}/golden/query_term.go.golden")
  stable_env = env_from_query_term_golden(golden)
  output = IO::Memory.new
  program = Bubbletea.new_program(
    QueryTermModel.new,
    Tea.with_input(IO::Memory.new("")),
    Tea.with_output(output),
    Tea.without_signals,
    Tea.with_window_size(80, 24),
    Tea.with_environment(stable_env),
  )
  spawn { sleep 60.milliseconds; program.send(Tea::QuitMsg.new) }
  _model, err = program.run; raise err.not_nil! if err; output.to_slice
end

describe "examples/query_term parity" do
  it "matches the saved Go golden output exactly" do
    capture_query_term_output.should eq(File.read("#{__DIR__}/golden/query_term.go.golden").to_slice)
  end
end
