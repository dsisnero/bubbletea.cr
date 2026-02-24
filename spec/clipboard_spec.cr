require "spec"
require "../src/bubbletea"

describe "Clipboard" do
  describe "ClipboardMsg" do
    it "stores content and selection" do
      msg = Tea::ClipboardMsg.new("hello", 'c'.ord.to_u8)
      msg.content.should eq "hello"
      msg.selection.should eq 'c'.ord.to_u8
      msg.clipboard.should eq 'c'.ord.to_u8
    end

    it "defaults to system clipboard" do
      msg = Tea::ClipboardMsg.new("test")
      msg.selection.should eq 'c'.ord.to_u8
    end

    it "converts to string" do
      msg = Tea::ClipboardMsg.new("content")
      msg.to_s.should eq "content"
    end
  end

  describe "SetClipboard" do
    it "creates a command" do
      cmd = Tea.set_clipboard("test content")
      cmd.should be_a(Tea::Cmd)

      msg = cmd.call
      msg.should be_a(Tea::SetClipboardMsg)
      msg.as(Tea::SetClipboardMsg).content.should eq "test content"
    end
  end

  describe "ReadClipboard" do
    it "creates a command" do
      cmd = Tea.read_clipboard
      cmd.should be_a(Tea::Cmd)

      msg = cmd.call
      msg.should be_a(Tea::ReadClipboardMsg)
    end
  end

  describe "SetPrimaryClipboard" do
    it "creates a command" do
      cmd = Tea.set_primary_clipboard("primary content")
      cmd.should be_a(Tea::Cmd)

      msg = cmd.call
      msg.should be_a(Tea::SetPrimaryClipboardMsg)
      msg.as(Tea::SetPrimaryClipboardMsg).content.should eq "primary content"
    end
  end

  describe "ReadPrimaryClipboard" do
    it "creates a command" do
      cmd = Tea.read_primary_clipboard
      cmd.should be_a(Tea::Cmd)

      msg = cmd.call
      msg.should be_a(Tea::ReadPrimaryClipboardMsg)
    end
  end
end
