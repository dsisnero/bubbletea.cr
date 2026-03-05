require "../spec_helper"
require "../../lib/bubbles/src/bubbles"
require "lipgloss"

private PADDING_PROGRESS_STATIC   = 2
private MAX_WIDTH_PROGRESS_STATIC = 80

private struct ProgressStaticTickMsg
  include Tea::Msg
end

private class ProgressStaticParityModel
  include Tea::Model

  def initialize
    @percent = 0.0
    @progress = Bubbles::Progress.new(
      Bubbles::Progress.with_scaled(true),
      Bubbles::Progress.with_colors(Lipgloss.color("#FF7CCB"), Lipgloss.color("#FDFF8C")),
    )
    @help_style = Lipgloss.new_style.foreground(Lipgloss.color("#626262"))
  end

  def init : Tea::Cmd?
    nil
  end

  def update(msg : Tea::Msg)
    case msg
    when Tea::KeyPressMsg
      return {self, Tea.quit}
    when Tea::WindowSizeMsg
      @progress.width = msg.width - PADDING_PROGRESS_STATIC * 2 - 4
      @progress.width = MAX_WIDTH_PROGRESS_STATIC if @progress.width > MAX_WIDTH_PROGRESS_STATIC
      return {self, nil}
    when ProgressStaticTickMsg
      @percent += 0.25
      if @percent > 1.0
        @percent = 1.0
        return {self, Tea.quit}
      end
      return {self, nil}
    else
      return {self, nil}
    end
  end

  def view : Tea::View
    pad = " " * PADDING_PROGRESS_STATIC
    Tea.new_view("\n" + pad + @progress.view_as(@percent) + "\n\n" + pad + @help_style.render("Press any key to quit"))
  end
end

private def capture_progress_static_output : Bytes
  output = IO::Memory.new
  program = Bubbletea.new_program(
    ProgressStaticParityModel.new,
    Tea.with_input(IO::Memory.new("")),
    Tea.with_output(output),
    Tea.without_signals,
    Tea.with_window_size(80, 24),
  )

  spawn do
    sleep 60.milliseconds
    5.times do
      program.send(ProgressStaticTickMsg.new)
      sleep 20.milliseconds
    end
  end

  _model, err = program.run
  raise err.not_nil! if err
  output.to_slice
end

describe "examples/progress_static parity" do
  it "matches the saved Go golden output exactly" do
    actual = capture_progress_static_output
    expected = File.read("#{__DIR__}/golden/progress_static.go.golden").to_slice
    actual.should eq(expected)
  end
end
