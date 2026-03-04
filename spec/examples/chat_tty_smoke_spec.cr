require "../spec_helper"
require "file_utils"

describe "examples/chat real-tty smoke" do
  it "starts and exits under a PTY without hanging" do
    temp_dir = File.join(Dir.current, "temp", "teatest", "chat_tty")
    FileUtils.mkdir_p(temp_dir)
    typescript = File.join(temp_dir, "chat.typescript")
    chat_bin = File.join(temp_dir, "chat_example")
    File.delete(typescript) if File.exists?(typescript)
    File.delete(chat_bin) if File.exists?(chat_bin)

    build_out = IO::Memory.new
    build_status = Process.run(
      "crystal",
      ["build", "examples/chat.cr", "-o", chat_bin],
      output: build_out,
      error: build_out,
      env: {"CRYSTAL_CACHE_DIR" => File.join(Dir.current, ".crystal-cache")}
    )
    build_status.exit_code.should eq(0), build_out.to_s

    stdin_data = IO::Memory.new("hi\r\e")
    process = Process.new(
      "script",
      [
        "-q",
        typescript,
        "env",
        "CRYSTAL_CACHE_DIR=#{File.join(Dir.current, ".crystal-cache")}",
        "BUBBLETEA_EXAMPLE_DISABLE_MAIN=0",
        chat_bin,
      ],
      input: stdin_data,
      output: Process::Redirect::Close,
      error: Process::Redirect::Close
    )

    done = Channel(Process::Status).new(1)
    spawn do
      done.send(process.wait)
    end

    status : Process::Status? = nil
    select
    when s = done.receive
      status = s
    when timeout(12.seconds)
      process.signal(Signal::TERM) rescue nil
      sleep 200.milliseconds
      process.signal(Signal::KILL) rescue nil
      fail "chat example hung under PTY (timeout after 12s)"
    end

    output = File.exists?(typescript) ? File.read(typescript) : ""
    if output.includes?("error opening TTY") || output.includes?("Operation not permitted")
      if ENV["STRICT_REAL_TTY_SPECS"]? == "1"
        fail "real PTY access is unavailable in this environment"
      end
      status.not_nil!.exit_code.should_not eq(0)
      next
    end

    status.not_nil!.exit_code.should eq(0)
    output.includes?("Welcome to the chat room!").should be_true, output
  end
end
