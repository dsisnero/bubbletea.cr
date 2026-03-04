require "spec"
require "../lib/lipgloss/src/lipgloss"

describe "Lipgloss color string parity" do
  it "treats numeric strings as indexed colors" do
    style = Lipgloss::Style.new.foreground("238").background("34")

    fg = style.foreground_color
    bg = style.background_color

    fg.should_not be_nil
    bg.should_not be_nil

    fg.try &.type.should eq(Lipgloss::Color::Type::Indexed)
    bg.try &.type.should eq(Lipgloss::Color::Type::Indexed)
    fg.try &.value.should eq(238)
    bg.try &.value.should eq(34)
  end

  it "still supports hex strings" do
    style = Lipgloss::Style.new.foreground("#123456")
    fg = style.foreground_color

    fg.should_not be_nil
    fg.try &.type.should eq(Lipgloss::Color::Type::RGB)
  end
end
