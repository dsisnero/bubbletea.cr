require "spec"
require "../src/bubbletea"

describe "Every" do
  it "returns expected message" do
    expected = "every ms"
    cmd = Tea.every(1.millisecond, ->(t : Time) { expected })
    msg = cmd.call
    msg.should eq expected
  end
end

describe "Tick" do
  it "returns expected message" do
    expected = "tick"
    cmd = Tea.tick(1.millisecond, ->(t : Time) { expected })
    msg = cmd.call
    msg.should eq expected
  end
end

describe "Sequentially" do
  it "handles all nil commands" do
    nil_return_cmd = -> { nil }
    cmd = Tea.sequentially(nil_return_cmd, nil_return_cmd)
    msg = cmd.call
    msg.should be_nil
  end

  it "handles null commands" do
    cmd = Tea.sequentially(nil, nil)
    msg = cmd.call
    msg.should be_nil
  end

  it "returns first error message" do
    expected_err = RuntimeError.new("some err")
    nil_return_cmd = -> { nil }
    err_cmd = -> { expected_err }
    cmd = Tea.sequentially(nil_return_cmd, err_cmd, nil_return_cmd)
    msg = cmd.call
    msg.should eq expected_err
  end

  it "returns first string message" do
    expected_str = "some msg"
    nil_return_cmd = -> { nil }
    str_cmd = -> { expected_str }
    cmd = Tea.sequentially(nil_return_cmd, str_cmd, nil_return_cmd)
    msg = cmd.call
    msg.should eq expected_str
  end
end

describe "Batch" do
  it "handles nil cmd" do
    cmd = Tea.batch(nil)
    cmd.should be_nil
  end

  it "handles empty cmd" do
    cmd = Tea.batch()
    cmd.should be_nil
  end

  it "returns single command directly" do
    single_cmd = -> { "single" }
    cmd = Tea.batch(single_cmd)
    cmd.should eq single_cmd
  end

  it "returns BatchMsg for multiple commands" do
    cmd1 = -> { "a" }
    cmd2 = -> { "b" }
    cmd = Tea.batch(cmd1, cmd2)
    cmd.should_not be_nil
    msg = cmd.call
    msg.should be_a(Tea::BatchMsg)
    batch_msg = msg.as(Tea::BatchMsg)
    batch_msg.commands.should eq [cmd1, cmd2]
  end
end

describe "Sequence" do
  it "handles nil cmd" do
    cmd = Tea.sequence(nil)
    cmd.should be_nil
  end

  it "handles empty cmd" do
    cmd = Tea.sequence()
    cmd.should be_nil
  end

  it "returns single command directly" do
    single_cmd = -> { "single" }
    cmd = Tea.sequence(single_cmd)
    cmd.should eq single_cmd
  end

  it "returns SequenceMsg for multiple commands" do
    cmd1 = -> { "a" }
    cmd2 = -> { "b" }
    cmd = Tea.sequence(cmd1, cmd2)
    cmd.should_not be_nil
    msg = cmd.call
    msg.should be_a(Tea::SequenceMsg)
    seq_msg = msg.as(Tea::SequenceMsg)
    seq_msg.commands.should eq [cmd1, cmd2]
  end
end