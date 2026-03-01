require "../src/bubbletea"

struct InstalledPkgMsg
  include Tea::Msg
  getter pkg : String

  def initialize(@pkg : String)
  end
end

private def download_and_install(pkg : String) : Bubbletea::Cmd
  delay = Random.rand(500).milliseconds
  Bubbletea.tick(delay, ->(_t : Time) { InstalledPkgMsg.new(pkg).as(Tea::Msg?) })
end

class PackageManagerModel
  include Bubbletea::Model

  def initialize
    @packages = %w[ansi lipgloss bubbletea bubbles glamour]
    @index = 0
    @width = 80
    @done = false
    @spinner = ["-", "\\", "|", "/"]
    @spin_index = 0
  end

  def init : Bubbletea::Cmd?
    Bubbletea.batch(download_and_install(@packages[@index]), spinner_tick)
  end

  def update(msg : Tea::Msg)
    case msg
    when Bubbletea::WindowSizeMsg
      @width = msg.width
    when Bubbletea::KeyPressMsg
      if msg.keystroke.in?({"ctrl+c", "esc", "q"})
        return {self, Bubbletea.quit}
      end
    when InstalledPkgMsg
      pkg = @packages[@index]
      if @index >= @packages.size - 1
        @done = true
        return {self, Bubbletea.sequence(Bubbletea.printf("✓ %s", pkg), Bubbletea.quit)}
      end

      @index += 1
      return {
        self,
        Bubbletea.batch(
          Bubbletea.printf("✓ %s", pkg),
          download_and_install(@packages[@index])
        ),
      }
    when Bubbletea::Value
      if msg.value == "spin"
        @spin_index = (@spin_index + 1) % @spinner.size
        return {self, spinner_tick}
      end
    end

    {self, nil}
  end

  def view : Bubbletea::View
    if @done
      return Bubbletea::View.new("Done! Installed #{@packages.size} packages.\n")
    end

    n = @packages.size
    count = "%d/%d" % {@index, n}
    spin = @spinner[@spin_index]
    pkg = @packages[@index]

    Bubbletea::View.new("#{spin} Installing #{pkg} ... #{count}")
  end

  private def spinner_tick : Bubbletea::Cmd
    Bubbletea.tick(100.milliseconds, ->(_t : Time) { Bubbletea["spin"].as(Tea::Msg?) })
  end
end

program = Bubbletea::Program.new(PackageManagerModel.new)
_model, err = program.run
if err
  STDERR.puts "Error running program: #{err.message}"
  exit 1
end
