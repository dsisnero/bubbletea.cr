require "bubbles"
require "lipgloss"
require "http/client"
require "json"

# Message types for async operations
struct GotReposSuccessMsg
  include Tea::Msg
  property repos : Array(String)

  def initialize(@repos : Array(String))
  end
end

struct GotReposErrMsg
  include Tea::Msg
  property error : Exception

  def initialize(@error : Exception)
  end
end

REPOS_URL = "https://api.github.com/orgs/charmbracelet/repos"

def get_repos : Tea::Cmd
  -> {
    begin
      response = HTTP::Client.get(REPOS_URL, headers: HTTP::Headers{
        "Accept"               => "application/vnd.github+json",
        "X-GitHub-Api-Version" => "2022-11-28",
      })

      if response.success?
        repos = Array(Hash(String, JSON::Any)).from_json(response.body)
        repo_names = repos.map(&.["name"].as_s)
        GotReposSuccessMsg.new(repo_names).as(Tea::Msg?)
      else
        GotReposErrMsg.new(Exception.new("HTTP #{response.status_code}")).as(Tea::Msg?)
      end
    rescue ex
      GotReposErrMsg.new(ex).as(Tea::Msg?)
    end
  }
end

struct Keymap
  include Bubbles::Help::KeyMap

  property complete : Bubbles::Key::Binding
  property next_key : Bubbles::Key::Binding
  property prev_key : Bubbles::Key::Binding
  property quit : Bubbles::Key::Binding

  def initialize
    @complete = Bubbles::Key.new_binding(
      Bubbles::Key.with_keys("tab"),
      Bubbles::Key.with_help("tab", "complete"),
      Bubbles::Key.with_disabled
    )
    @next_key = Bubbles::Key.new_binding(
      Bubbles::Key.with_keys("ctrl+n"),
      Bubbles::Key.with_help("ctrl+n", "next"),
      Bubbles::Key.with_disabled
    )
    @prev_key = Bubbles::Key.new_binding(
      Bubbles::Key.with_keys("ctrl+p"),
      Bubbles::Key.with_help("ctrl+p", "prev"),
      Bubbles::Key.with_disabled
    )
    @quit = Bubbles::Key.new_binding(
      Bubbles::Key.with_keys("enter", "ctrl+c", "esc"),
      Bubbles::Key.with_help("esc", "quit")
    )
  end

  def short_help : Array(Bubbles::Key::Binding)
    [@complete, @next_key, @prev_key, @quit]
  end

  def full_help : Array(Array(Bubbles::Key::Binding))
    [short_help]
  end
end

class AutoCompleteModel
  include Tea::Model

  @text_input : Bubbles::TextInput::Model
  @help : Bubbles::Help::Model
  @keymap : Keymap

  def initialize
    @text_input = Bubbles::TextInput.new
    @text_input.prompt = "charmbracelet/"
    @text_input.focus
    @text_input.char_limit = 50
    @text_input.show_suggestions = true

    # Style the prompt
    styles = @text_input.styles
    styles.focused.prompt = Lipgloss::Style.new.foreground(Lipgloss.color("63")).margin_left(2)
    styles.cursor.color = "63"
    @text_input.set_styles(styles)

    @help = Bubbles::Help::Model.new
    @keymap = Keymap.new
  end

  def init : Tea::Cmd
    get_repos
  end

  def update(msg : Tea::Msg)
    case msg
    when GotReposSuccessMsg
      @text_input.set_suggestions(msg.repos)
    when Tea::KeyPressMsg
      if Bubbles::Key.matches?(msg, @keymap.quit)
        return {self, Tea.quit}
      end
    end

    # Update text input
    updated_input, cmd = @text_input.update(msg)
    @text_input = updated_input

    # Update keymap enabled states based on available suggestions
    has_choices = @text_input.matched_suggestions.size > 1
    # Note: Bubbles::Key doesn't have with_enabled, bindings are enabled by default
    # We need to create new bindings with appropriate enabled state
    if has_choices
      @keymap.complete = Bubbles::Key.new_binding(
        Bubbles::Key.with_keys("tab"),
        Bubbles::Key.with_help("tab", "complete")
      )
      @keymap.next_key = Bubbles::Key.new_binding(
        Bubbles::Key.with_keys("ctrl+n"),
        Bubbles::Key.with_help("ctrl+n", "next")
      )
      @keymap.prev_key = Bubbles::Key.new_binding(
        Bubbles::Key.with_keys("ctrl+p"),
        Bubbles::Key.with_help("ctrl+p", "prev")
      )
    else
      @keymap.complete = Bubbles::Key.new_binding(
        Bubbles::Key.with_keys("tab"),
        Bubbles::Key.with_help("tab", "complete"),
        Bubbles::Key.with_disabled
      )
      @keymap.next_key = Bubbles::Key.new_binding(
        Bubbles::Key.with_keys("ctrl+n"),
        Bubbles::Key.with_help("ctrl+n", "next"),
        Bubbles::Key.with_disabled
      )
      @keymap.prev_key = Bubbles::Key.new_binding(
        Bubbles::Key.with_keys("ctrl+p"),
        Bubbles::Key.with_help("ctrl+p", "prev"),
        Bubbles::Key.with_disabled
      )
    end

    {self, cmd}
  end

  def view : Tea::View
    if @text_input.available_suggestions.empty?
      return Tea.new_view("One sec, we're fetching completions...")
    end

    content = Lipgloss.join_vertical(
      Lipgloss::Position::Left,
      header_view,
      @text_input.view,
      footer_view
    )

    Tea.new_view(content)
  end

  private def header_view : String
    "Enter a Charm™ repo:\n"
  end

  private def footer_view : String
    "\n" + @help.view(@keymap)
  end
end

program = Tea::Program.new(AutoCompleteModel.new)
_model, err = program.run
if err
  STDERR.puts "Error running program: #{err.message}"
  exit 1
end
