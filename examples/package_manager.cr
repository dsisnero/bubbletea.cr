require "../lib/bubbles/src/bubbles"
require "lipgloss"

struct InstalledPkgMsg
  include Tea::Msg
  getter pkg : String

  def initialize(@pkg : String)
  end
end

PACKAGE_MANAGER_CURRENT_PKG_STYLE = Lipgloss::Style.new.foreground("211")
PACKAGE_MANAGER_DONE_STYLE = Lipgloss::Style.new.margin(1, 2)
PACKAGE_MANAGER_CHECKMARK = "\e[38;5;42m✓\e[m"

PACKAGE_MANAGER_PACKAGES = [
  "vegeutils",
  "libgardening",
  "currykit",
  "spicerack",
  "fullenglish",
  "eggy",
  "bad-kitty",
  "chai",
  "hojicha",
  "libtacos",
  "babys-monads",
  "libpurring",
  "currywurst-devel",
  "xmodmeow",
  "licorice-utils",
  "cashew-apple",
  "rock-lobster",
  "standmixer",
  "coffee-CUPS",
  "libesszet",
  "zeichenorientierte-benutzerschnittstellen",
  "schnurrkit",
  "old-socks-devel",
  "jalapeño",
  "molasses-utils",
  "xkohlrabi",
  "party-gherkin",
  "snow-peas",
  "libyuzu",
]

private def get_packages(rng : Random = Random.new) : Array(String)
  pkgs = PACKAGE_MANAGER_PACKAGES.dup
  (pkgs.size - 1).downto(1) do |i|
    j = rng.rand(i + 1)
    pkgs[i], pkgs[j] = pkgs[j], pkgs[i]
  end

  pkgs.map do |pkg|
    "#{pkg}-#{rng.rand(10)}.#{rng.rand(10)}.#{rng.rand(10)}"
  end
end

private def download_and_install(pkg : String, rng : Random) : Bubbletea::Cmd
  delay = rng.rand(500).milliseconds
  Bubbletea.tick(delay, ->(_t : Time) { InstalledPkgMsg.new(pkg).as(Tea::Msg?) })
end

class PackageManagerModel
  include Bubbletea::Model

  property packages : Array(String)
  property index : Int32

  def initialize(@rng : Random = Random.new, packages : Array(String)? = nil)
    @packages = packages || get_packages(@rng)
    @index = 0
    @width = 0
    @height = 0
    @done = false

    @progress = Bubbles::Progress.new(
      Bubbles::Progress.with_default_blend,
      Bubbles::Progress.with_width(40),
      Bubbles::Progress.without_percentage,
    )

    @spinner = Bubbles::Spinner.new
    @spinner.style = Lipgloss::Style.new.foreground(Lipgloss.color("63"))
  end

  def init : Bubbletea::Cmd?
    Bubbletea.batch(
      download_and_install(@packages[@index], @rng),
      -> { @spinner.tick.as(Tea::Msg?) },
    )
  end

  def update(msg : Tea::Msg)
    case msg
    when Bubbletea::WindowSizeMsg
      @width = msg.width
      @height = msg.height
    when Bubbletea::KeyPressMsg
      return {self, Bubbletea.quit} if msg.keystroke.in?({"ctrl+c", "esc", "q"})
    when InstalledPkgMsg
      pkg = @packages[@index]
      if @index >= @packages.size - 1
        @done = true
        return {
          self,
          Bubbletea.sequence(
            Bubbletea.printf("%s %s", PACKAGE_MANAGER_CHECKMARK, pkg),
            Bubbletea.quit,
          ),
        }
      end

      @index += 1
      progress_cmd = @progress.set_percent(@index.to_f / @packages.size.to_f)

      return {
        self,
        Bubbletea.batch(
          progress_cmd,
          Bubbletea.printf("%s %s", PACKAGE_MANAGER_CHECKMARK, pkg),
          download_and_install(@packages[@index], @rng),
        ),
      }
    when Bubbles::Spinner::TickMsg
      @spinner, cmd = @spinner.update(msg)
      return {self, cmd}
    when Bubbles::Progress::FrameMsg
      @progress, cmd = @progress.update(msg)
      return {self, cmd}
    end

    {self, nil}
  end

  def view : Bubbletea::View
    n = @packages.size
    w = Lipgloss.width(n.to_s)

    if @done
      return Bubbletea::View.new(PACKAGE_MANAGER_DONE_STYLE.render("Done! Installed #{n} packages.\n"))
    end

    pkg_count = " %*d/%*d" % {w, @index, w, n}
    spin = @spinner.view + " "
    prog = @progress.view
    cells_avail = {@width - Lipgloss.width(spin + prog + pkg_count), 0}.max

    pkg_name = PACKAGE_MANAGER_CURRENT_PKG_STYLE.render(@packages[@index])
    info = Lipgloss::Style.new.max_width(cells_avail).render("Installing #{pkg_name}")

    cells_remaining = {@width - Lipgloss.width(spin + info + prog + pkg_count), 0}.max
    gap = " " * cells_remaining

    Bubbletea::View.new(spin + info + gap + prog + pkg_count)
  end
end

unless ENV["BUBBLETEA_EXAMPLE_DISABLE_MAIN"]? == "1"
  program = Bubbletea::Program.new(PackageManagerModel.new)
  _model, err = program.run
  if err
    STDERR.puts "Error running program: #{err.message}"
    exit 1
  end
end
