require "../src/bubbletea"
require "lipgloss"
require "colorful"

VIEWS_PROGRESS_BAR_WIDTH = 71
VIEWS_PROGRESS_FULL_CHAR = "█"
VIEWS_PROGRESS_EMPTY_CHAR = "░"
VIEWS_DOT_CHAR = " • "

VIEWS_KEYWORD_STYLE = Lipgloss::Style.new.foreground(Lipgloss.color("211"))
VIEWS_SUBTLE_STYLE = Lipgloss::Style.new.foreground(Lipgloss.color("241"))
VIEWS_TICKS_STYLE = Lipgloss::Style.new.foreground(Lipgloss.color("79"))
VIEWS_CHECKBOX_STYLE = Lipgloss::Style.new.foreground(Lipgloss.color("212"))
VIEWS_PROGRESS_EMPTY = VIEWS_SUBTLE_STYLE.render(VIEWS_PROGRESS_EMPTY_CHAR)
VIEWS_DOT_STYLE = Lipgloss::Style.new.foreground(Lipgloss.color("236")).render(VIEWS_DOT_CHAR)
VIEWS_MAIN_STYLE = Lipgloss::Style.new.margin_left(2)
VIEWS_RAMP = begin
  styles = [] of Lipgloss::Style
  color_a = Colorful::Color.hex("#B14FFF")
  color_b = Colorful::Color.hex("#00FFA3")
  (0...VIEWS_PROGRESS_BAR_WIDTH).each do |i|
    c = color_a.blend_luv(color_b, i.to_f64 / VIEWS_PROGRESS_BAR_WIDTH.to_f64)
    styles << Lipgloss::Style.new.foreground(Lipgloss.color(c.hex))
  end
  styles
end

struct ViewsTickMsg
  include Tea::Msg
end

struct ViewsFrameMsg
  include Tea::Msg
end

private def views_out_bounce(t : Float64) : Float64
  if t < (4.0 / 11.0)
    (121.0 * t * t) / 16.0
  elsif t < (8.0 / 11.0)
    (363.0 / 40.0 * t * t) - (99.0 / 10.0 * t) + 17.0 / 5.0
  elsif t < (9.0 / 10.0)
    (4356.0 / 361.0 * t * t) - (35442.0 / 1805.0 * t) + 16061.0 / 1805.0
  else
    (54.0 / 5.0 * t * t) - (513.0 / 25.0 * t) + 268.0 / 25.0
  end
end

private def views_checkbox(label : String, checked : Bool) : String
  if checked
    VIEWS_CHECKBOX_STYLE.render("[x] #{label}")
  else
    "[ ] #{label}"
  end
end

private def views_progress_bar(percent : Float64) : String
  full_size = (VIEWS_PROGRESS_BAR_WIDTH.to_f64 * percent).round.to_i
  full_cells = String.build do |io|
    full_size.times do |i|
      io << VIEWS_RAMP[i].render(VIEWS_PROGRESS_FULL_CHAR)
    end
  end
  empty_cells = VIEWS_PROGRESS_EMPTY * (VIEWS_PROGRESS_BAR_WIDTH - full_size)
  "#{full_cells}#{empty_cells} #{(percent * 100).round.to_i.to_s.rjust(3)}"
end

private def views_tick_cmd : Bubbletea::Cmd
  Bubbletea.tick(1.second, ->(_t : Time) { ViewsTickMsg.new.as(Tea::Msg?) })
end

private def views_frame_cmd : Bubbletea::Cmd
  Bubbletea.tick((1.second / 60.0), ->(_t : Time) { ViewsFrameMsg.new.as(Tea::Msg?) })
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
    views_tick_cmd
  end

  def update(msg : Tea::Msg)
    if key = msg.as?(Tea::KeyPressMsg)
      k = key.string
      if k == "q" || k == "esc" || k == "ctrl+c"
        @quitting = true
        return {self, Tea.quit}
      end
    end

    unless @chosen
      return update_choices(msg)
    end
    update_chosen(msg)
  end

  def view : Bubbletea::View
    return Tea.new_view("\n  See you later!\n\n") if @quitting

    s = if @chosen
          chosen_view
        else
          choices_view
        end

    Tea.new_view(VIEWS_MAIN_STYLE.render("\n#{s}\n"))
  end

  private def update_choices(msg : Tea::Msg)
    case msg
    when Tea::KeyPressMsg
      case msg.string
      when "j", "down"
        @choice += 1
        @choice = 3 if @choice > 3
      when "k", "up"
        @choice -= 1
        @choice = 0 if @choice < 0
      when "enter"
        @chosen = true
        return {self, views_frame_cmd}
      end
    when ViewsTickMsg
      if @ticks == 0
        @quitting = true
        return {self, Tea.quit}
      end
      @ticks -= 1
      return {self, views_tick_cmd}
    end

    {self, nil}
  end

  private def update_chosen(msg : Tea::Msg)
    case msg
    when ViewsFrameMsg
      unless @loaded
        @frames += 1
        @progress = views_out_bounce(@frames.to_f64 / 100.0)
        if @progress >= 1.0
          @progress = 1.0
          @loaded = true
          @ticks = 3
          return {self, views_tick_cmd}
        end
        return {self, views_frame_cmd}
      end
    when ViewsTickMsg
      if @loaded
        if @ticks == 0
          @quitting = true
          return {self, Tea.quit}
        end
        @ticks -= 1
        return {self, views_tick_cmd}
      end
    end

    {self, nil}
  end

  private def choices_view : String
    choices = String.build do |io|
      io << views_checkbox("Plant carrots", @choice == 0) << '\n'
      io << views_checkbox("Go to the market", @choice == 1) << '\n'
      io << views_checkbox("Read something", @choice == 2) << '\n'
      io << views_checkbox("See friends", @choice == 3)
    end

    "What to do today?\n\n#{choices}\n\nProgram quits in #{VIEWS_TICKS_STYLE.render(@ticks.to_s)} seconds\n\n" \
      "#{VIEWS_SUBTLE_STYLE.render("j/k, up/down: select")}#{VIEWS_DOT_STYLE}" \
      "#{VIEWS_SUBTLE_STYLE.render("enter: choose")}#{VIEWS_DOT_STYLE}" \
      "#{VIEWS_SUBTLE_STYLE.render("q, esc: quit")}"
  end

  private def chosen_view : String
    msg = case @choice
          when 0
            "Carrot planting?\n\nCool, we'll need #{VIEWS_KEYWORD_STYLE.render("libgarden")} and #{VIEWS_KEYWORD_STYLE.render("vegeutils")}..."
          when 1
            "A trip to the market?\n\nOkay, then we should install #{VIEWS_KEYWORD_STYLE.render("marketkit")} and #{VIEWS_KEYWORD_STYLE.render("libshopping")}..."
          when 2
            "Reading time?\n\nOkay, cool, then we’ll need a library. Yes, an #{VIEWS_KEYWORD_STYLE.render("actual library")}."
          else
            "It’s always good to see friends.\n\nFetching #{VIEWS_KEYWORD_STYLE.render("social-skills")} and #{VIEWS_KEYWORD_STYLE.render("conversationutils")}..."
          end

    label = if @loaded
              "Downloaded. Exiting in #{VIEWS_TICKS_STYLE.render(@ticks.to_s)} seconds..."
            else
              "Downloading..."
            end

    "#{msg}\n\n#{label}\n#{views_progress_bar(@progress)}%"
  end
end

unless ENV["BUBBLETEA_EXAMPLE_DISABLE_MAIN"]? == "1"
  program = Bubbletea::Program.new(ViewsModel.new)
  _model, err = program.run
  if err
    STDERR.puts "could not start program: #{err.message}"
    exit 1
  end
end
