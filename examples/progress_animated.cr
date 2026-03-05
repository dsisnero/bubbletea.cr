require "../src/bubbletea"
require "bubbles"
require "lipgloss"

PROGRESS_ANIM_PADDING   = 2
PROGRESS_ANIM_MAX_WIDTH = 80
PROGRESS_ANIM_HELP_STYLE = Lipgloss::Style.new.foreground(Lipgloss.color("#626262"))

struct ProgressAnimatedTickMsg
  include Tea::Msg
end

private def progress_animated_tick_cmd : Bubbletea::Cmd
  Bubbletea.tick(1.second, ->(_t : Time) { ProgressAnimatedTickMsg.new.as(Tea::Msg?) })
end

class ProgressAnimatedModel
  include Bubbletea::Model

  def initialize
    @progress = Bubbles::Progress.new(Bubbles::Progress.with_default_blend)
  end

  def init : Bubbletea::Cmd?
    progress_animated_tick_cmd
  end

  def update(msg : Tea::Msg)
    case msg
    when Bubbletea::KeyPressMsg
      {self, Bubbletea.quit}
    when Bubbletea::WindowSizeMsg
      @progress.set_width(msg.width - PROGRESS_ANIM_PADDING * 2 - 4)
      if @progress.width > PROGRESS_ANIM_MAX_WIDTH
        @progress.set_width(PROGRESS_ANIM_MAX_WIDTH)
      end
      {self, nil}
    when ProgressAnimatedTickMsg
      return {self, Bubbletea.quit} if @progress.percent == 1.0

      cmd = @progress.incr_percent(0.25)
      {self, Bubbletea.batch(progress_animated_tick_cmd, cmd)}
    when Bubbles::Progress::FrameMsg
      @progress, cmd = @progress.update(msg)
      {self, cmd}
    else
      {self, nil}
    end
  end

  def view : Bubbletea::View
    pad = " " * PROGRESS_ANIM_PADDING
    Bubbletea::View.new(
      "\n" +
      pad + @progress.view + "\n\n" +
      pad + PROGRESS_ANIM_HELP_STYLE.render("Press any key to quit")
    )
  end
end

unless ENV["BUBBLETEA_EXAMPLE_DISABLE_MAIN"]? == "1"
  program = Bubbletea::Program.new(ProgressAnimatedModel.new)
  _model, err = program.run
  if err
    STDERR.puts "Oh no! #{err.message}"
    exit 1
  end
end
