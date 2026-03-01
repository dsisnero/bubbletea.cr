require "../src/bubbletea"

struct ViewsTickMsg
  include Tea::Msg
end

struct ViewsFrameMsg
  include Tea::Msg
end

class ViewsModel
  include Bubbletea::Model

  def initialize
    @choice = 0
    @chosen = false
    @ticks = 10
    @frames = 0
    @progress = 0.0
    @loaded = false
    @quitting = false
  end

  def init : Bubbletea::Cmd?
    tick
  end

  def update(msg : Tea::Msg)
    if key = msg.as?(Bubbletea::KeyPressMsg)
      case key.keystroke
      when "q", "esc", "ctrl+c"
        @quitting = true
        return {self, Bubbletea.quit}
      end
    end

    return update_choices(msg) unless @chosen
    update_chosen(msg)
  end

  def view : Bubbletea::View
    return Bubbletea::View.new("\n  See you later!\n\n") if @quitting

    s = @chosen ? chosen_view : choices_view
    Bubbletea::View.new("\n#{s}\n")
  end

  private def update_choices(msg : Tea::Msg)
    case msg
    when Bubbletea::KeyPressMsg
      case msg.keystroke
      when "j", "down"
        @choice = {@choice + 1, 3}.min
      when "k", "up"
        @choice = {@choice - 1, 0}.max
      when "enter"
        @chosen = true
        return {self, frame}
      end
    when ViewsTickMsg
      if @ticks == 0
        @quitting = true
        return {self, Bubbletea.quit}
      end
      @ticks -= 1
      return {self, tick}
    end

    {self, nil}
  end

  private def update_chosen(msg : Tea::Msg)
    case msg
    when ViewsFrameMsg
      unless @loaded
        @frames += 1
        @progress = {@frames / 100.0, 1.0}.min
        if @progress >= 1.0
          @loaded = true
          @ticks = 3
          return {self, tick}
        end
        return {self, frame}
      end
    when ViewsTickMsg
      if @loaded
        if @ticks == 0
          @quitting = true
          return {self, Bubbletea.quit}
        end
        @ticks -= 1
        return {self, tick}
      end
    end

    {self, nil}
  end

  private def choices_view : String
    choices = ["Plant carrots", "Go to the market", "Read something", "See friends"]
    body = choices.map_with_index { |c, i| i == @choice ? "[x] #{c}" : "[ ] #{c}" }.join("\n")
    "What to do today?\n\n#{body}\n\nProgram quits in #{@ticks} seconds"
  end

  private def chosen_view : String
    label = @loaded ? "Downloaded. Exiting in #{@ticks} seconds..." : "Downloading..."
    percent = (@progress * 100).round.to_i
    "Task chosen: #{@choice + 1}\n\n#{label}\n#{"█" * (percent // 5)}#{"░" * (20 - (percent // 5))} #{percent}%"
  end

  private def tick : Bubbletea::Cmd
    Bubbletea.tick(1.second, ->(_t : Time) { ViewsTickMsg.new.as(Tea::Msg?) })
  end

  private def frame : Bubbletea::Cmd
    Bubbletea.tick(16.milliseconds, ->(_t : Time) { ViewsFrameMsg.new.as(Tea::Msg?) })
  end
end

program = Bubbletea::Program.new(ViewsModel.new)
_model, err = program.run
if err
  STDERR.puts "could not start program: #{err.message}"
  exit 1
end
