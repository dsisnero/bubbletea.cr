require "../spec_helper"

ENV["BUBBLETEA_EXAMPLE_DISABLE_MAIN"] = "1"
require "../../examples/list_fancy"

describe "examples/list_fancy behavior" do
  it "toggles help on H and inserts an item on a" do
    RandomFancyItemGenerator.seed(1_i64)
    model = ListFancyModel.new

    before_help = model.list.show_help
    before_count = model.list.items.size

    updated, _cmd = model.update(Tea.key('H'))
    model = updated.as(ListFancyModel)
    model.list.show_help.should eq(!before_help)

    updated, cmd = model.update(Tea.key('a'))
    model = updated.as(ListFancyModel)

    # InsertItem and status-message updates are command-driven, matching Go list behavior.
    if command = cmd
      if message = command.call
        model.update(message)
      end
    end

    model.list.items.size.should eq(before_count + 1)
  end

  it "quits on q" do
    RandomFancyItemGenerator.seed(1_i64)
    model = ListFancyModel.new
    _updated, cmd = model.update(Tea.key('q'))
    cmd.not_nil!.call.should be_a(Tea::QuitMsg)
  end
end
