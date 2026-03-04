require "../spec_helper"

ENV["BUBBLETEA_EXAMPLE_DISABLE_MAIN"] = "1"
require "../../examples/capability"

describe "examples/capability behavior" do
  it "requests typed capability on enter" do
    model = CapabilityModel.new
    init_cmd = model.init
    init_cmd.try(&.call)

    model.update(Tea.key('R'))
    model.update(Tea.key('G'))
    model.update(Tea.key('B'))
    _m, cmd = model.update(Tea.key(Tea::KeyEnter))

    cmd.should_not be_nil
    msg = cmd.not_nil!.call
    msg.should be_a(Tea::RequestCapabilityMsg)
    msg.as(Tea::RequestCapabilityMsg).capability.should eq("RGB")
  end

  it "quits on ctrl+c" do
    model = CapabilityModel.new
    init_cmd = model.init
    init_cmd.try(&.call)

    _m, cmd = model.update(Tea.key('c', Tea::ModCtrl))
    cmd.should_not be_nil
    cmd.not_nil!.call.should be_a(Tea::QuitMsg)
  end
end
