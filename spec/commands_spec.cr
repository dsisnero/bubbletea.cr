require "spec"
require "../src/bubbletea"

describe "Every" do
  it "returns expected message" do
    expected = "every ms"
    cmd = Tea.every(1.millisecond) { Tea.wrap(expected) }
    msg = cmd.call
    msg.should be_a(Tea::Value(String))
    msg.as(Tea::Value(String)).value.should eq expected
  end
end

describe "Tick" do
  it "returns expected message" do
    expected = "tick"
    cmd = Tea.tick(1.millisecond) { Tea.wrap(expected) }
    msg = cmd.call
    msg.should be_a(Tea::Value(String))
    msg.as(Tea::Value(String)).value.should eq expected
  end
end

describe "Sequentially" do
  it "handles all nil commands" do
    nil_return_cmd = -> { nil.as(Tea::Msg?) }.as(Tea::Cmd)
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
    nil_return_cmd = -> { nil.as(Tea::Msg?) }.as(Tea::Cmd)
    err_cmd = -> { Tea.wrap(expected_err).as(Tea::Msg?) }
    cmd = Tea.sequentially(nil_return_cmd, err_cmd, nil_return_cmd)
    msg = cmd.call
    msg.should be_a(Tea::Value(RuntimeError))
    msg.as(Tea::Value(RuntimeError)).value.should eq expected_err
  end

  it "returns first string message" do
    expected_str = "some msg"
    nil_return_cmd = -> { nil.as(Tea::Msg?) }.as(Tea::Cmd)
    str_cmd = -> { Tea.wrap(expected_str).as(Tea::Msg?) }
    cmd = Tea.sequentially(nil_return_cmd, str_cmd, nil_return_cmd)
    msg = cmd.call
    msg.should be_a(Tea::Value(String))
    msg.as(Tea::Value(String)).value.should eq expected_str
  end
end

describe "Batch" do
  it "handles nil cmd" do
    cmd = Tea.batch(nil)
    cmd.should be_nil
  end

  it "handles empty cmd" do
    cmd = Tea.batch
    cmd.should be_nil
  end

  it "returns single command directly" do
    single_cmd = -> { Tea.wrap("single").as(Tea::Msg?) }
    cmd = Tea.batch(single_cmd)
    cmd.should eq single_cmd
  end

  it "returns BatchMsg for multiple commands" do
    cmd1 = -> { Tea.wrap("a").as(Tea::Msg?) }
    cmd2 = -> { Tea.wrap("b").as(Tea::Msg?) }
    cmd = Tea.batch(cmd1, cmd2)
    cmd.should_not be_nil
    msg = cmd.not_nil!.call
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
    cmd = Tea.sequence
    cmd.should be_nil
  end

  it "returns single command directly" do
    single_cmd = -> { Tea.wrap("single").as(Tea::Msg?) }
    cmd = Tea.sequence(single_cmd)
    cmd.should eq single_cmd
  end

  it "returns SequenceMsg for multiple commands" do
    cmd1 = -> { Tea.wrap("a").as(Tea::Msg?) }
    cmd2 = -> { Tea.wrap("b").as(Tea::Msg?) }
    cmd = Tea.sequence(cmd1, cmd2)
    cmd.should_not be_nil
    msg = cmd.not_nil!.call
    msg.should be_a(Tea::SequenceMsg)
    seq_msg = msg.as(Tea::SequenceMsg)
    seq_msg.commands.should eq [cmd1, cmd2]
  end
end
