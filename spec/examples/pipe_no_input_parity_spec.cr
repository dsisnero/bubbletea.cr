require "../spec_helper"

describe "examples/pipe no-input parity" do
  it "matches Go output when stdin is empty and not a pipe" do
    output = IO::Memory.new

    status = File.open("/dev/null") do |dev_null|
      Process.run(
        "crystal",
        ["run", "examples/pipe.cr"],
        input: dev_null,
        output: output,
        error: Process::Redirect::Close,
        env: {
          "CRYSTAL_CACHE_DIR"              => File.join(Dir.current, ".crystal-cache"),
          "BUBBLETEA_EXAMPLE_DISABLE_MAIN" => "0",
        }
      )
    end

    status.exit_code.should eq(1)

    actual = output.to_s
    expected = File.read("#{__DIR__}/golden/pipe_no_input.go.golden")
    actual.should eq(expected)
  end
end
