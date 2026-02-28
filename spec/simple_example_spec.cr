require "./spec_helper"
require "../examples/simple"

describe SimpleModel do
  it "initializes with a tick command" do
    model = SimpleModel.new(5)
    model.init.should_not be_nil
  end

  it "decrements on tick" do
    model = SimpleModel.new(5)
    updated, cmd = model.update(SimpleTickMsg.new)
    updated.as(SimpleModel).remaining.should eq(4)
    cmd.should_not be_nil
  end

  it "quits when countdown reaches zero" do
    model = SimpleModel.new(1)
    _updated, cmd = model.update(SimpleTickMsg.new)
    cmd.should_not be_nil
    cmd.not_nil!.call.should be_a(Tea::QuitMsg)
  end
end
