require "./spec_helper"

describe Bubbletea do
  it "provides access to Tea module" do
    Bubbletea::VERSION.should eq(Tea::VERSION)
  end

  it "wraps values as messages" do
    msg = Bubbletea.wrap("test")
    msg.should be_a(Tea::Value(String))
  end

  it "creates commands" do
    cmd = Bubbletea.batch
    cmd.should be_nil
  end

  it "provides quit command" do
    cmd = Bubbletea.quit
    cmd.should be_a(Tea::Cmd)
    msg = cmd.call
    msg.should be_a(Tea::QuitMsg)
  end

  it "provides key constants" do
    Bubbletea::ModShift.should eq(Tea::ModShift)
    Bubbletea::ModCtrl.should eq(Tea::ModCtrl)
  end
end
