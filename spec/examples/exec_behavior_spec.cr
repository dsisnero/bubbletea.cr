require "../spec_helper"

ENV["BUBBLETEA_EXAMPLE_DISABLE_MAIN"] = "1"
require "../../examples/exec"

describe "examples/exec behavior" do
  it "toggles alt screen with a" do
    model = Model.new
    model.altscreen_active.should eq(false)
    updated, cmd = model.update(Tea.key('a'))
    updated.as(Model).altscreen_active.should eq(true)
    cmd.should be_nil
  end

  it "returns an exec command with e" do
    model = Model.new
    _updated, cmd = model.update(Tea.key('e'))
    cmd.should_not be_nil
    cmd.not_nil!.call.should be_a(Tea::ExecMsg)
  end

  it "quits on ctrl+c" do
    model = Model.new
    _updated, cmd = model.update(Tea.key('c', Tea::ModCtrl))
    cmd.should_not be_nil
    cmd.not_nil!.call.should be_a(Tea::QuitMsg)
  end
end
