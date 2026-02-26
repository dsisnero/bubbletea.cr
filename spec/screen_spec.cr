require "spec"
require "../src/bubbletea"

# Test model for screen tests
class ScreenTestModel
  include Tea::Model

  property? alt_screen : Bool = false
  property mouse_mode : Tea::MouseMode = Tea::MouseMode::None
  property? show_cursor : Bool = false
  property? disable_bp : Bool = false
  property? report_event_types : Bool = false
  property bg_color : Colorful::Color? = nil

  def initialize
  end

  def init : Tea::Cmd?
    nil
  end

  def update(msg : Tea::Msg) : Tuple(Tea::Model, Tea::Cmd?)
    {self, nil}
  end

  def view : Tea::View
    view = Tea::View.new("test view")
    view.alt_screen = @alt_screen
    view.mouse_mode = @mouse_mode
    view.disable_bracketed_paste = @disable_bp
    view.keyboard_enhancements = Tea::KeyboardEnhancements.new(
      report_event_types: @report_event_types
    )
    view.background_color = @bg_color
    if @show_cursor
      view.cursor = Tea::Cursor.new(0, 0)
    end
    view
  end
end

describe "Screen" do
  describe "Go parity screen tests" do
    it "ports TestClearMsg semantics" do
      Tea.clear_screen.should be_a(Tea::Cmd)
      Tea.read_clipboard.should be_a(Tea::Cmd)
      Tea.set_clipboard("success").should be_a(Tea::Cmd)
      Tea.request_foreground_color.should be_a(Tea::Cmd)
      Tea.request_background_color.should be_a(Tea::Cmd)
      Tea.request_cursor_color.should be_a(Tea::Cmd)
    end

    it "ports TestViewModel semantics" do
      model = ScreenTestModel.new
      model.alt_screen = true
      model.mouse_mode = Tea::MouseMode::AllMotion
      model.show_cursor = true
      model.disable_bp = true
      model.report_event_types = true
      model.bg_color = Colorful::Color.hex("#FFFFFF")

      view = model.view
      view.alt_screen?.should be_true
      view.mouse_mode.should eq Tea::MouseMode::AllMotion
      view.cursor.should_not be_nil
      view.disable_bracketed_paste?.should be_true
      view.keyboard_enhancements.report_event_types?.should be_true
      view.background_color.should eq Colorful::Color.hex("#FFFFFF")
    end
  end

  describe "View options" do
    it "toggles alt screen" do
      model = ScreenTestModel.new
      model.alt_screen = true

      view = model.view
      view.alt_screen?.should be_true

      model.alt_screen = false
      view = model.view
      view.alt_screen?.should be_false
    end

    it "sets mouse mode to cell motion" do
      model = ScreenTestModel.new
      model.mouse_mode = Tea::MouseMode::CellMotion

      view = model.view
      view.mouse_mode.should eq Tea::MouseMode::CellMotion
    end

    it "sets mouse mode to all motion" do
      model = ScreenTestModel.new
      model.mouse_mode = Tea::MouseMode::AllMotion

      view = model.view
      view.mouse_mode.should eq Tea::MouseMode::AllMotion
    end

    it "disables mouse mode" do
      model = ScreenTestModel.new
      model.mouse_mode = Tea::MouseMode::AllMotion

      view = model.view
      view.mouse_mode.should eq Tea::MouseMode::AllMotion

      model.mouse_mode = Tea::MouseMode::None
      view = model.view
      view.mouse_mode.should eq Tea::MouseMode::None
    end

    it "hides cursor by default" do
      model = ScreenTestModel.new
      model.show_cursor = false

      view = model.view
      view.cursor.should be_nil
    end

    it "shows cursor when enabled" do
      model = ScreenTestModel.new
      model.show_cursor = true

      view = model.view
      cursor = view.cursor
      cursor.should_not be_nil
      cursor.try do |c|
        c.x.should eq 0
        c.y.should eq 0
      end
    end

    it "toggles bracketed paste mode" do
      model = ScreenTestModel.new
      model.disable_bp = true

      view = model.view
      view.disable_bracketed_paste?.should be_true

      model.disable_bp = false
      view = model.view
      view.disable_bracketed_paste?.should be_false
    end

    it "toggles keyboard event types reporting" do
      model = ScreenTestModel.new
      model.report_event_types = false

      view = model.view
      view.keyboard_enhancements.report_event_types?.should be_false

      model.report_event_types = true
      view = model.view
      view.keyboard_enhancements.report_event_types?.should be_true
    end

    it "sets background color" do
      model = ScreenTestModel.new
      model.bg_color = Colorful::Color.hex("#FF0000")
      view = model.view
      view.background_color.should eq Colorful::Color.hex("#FF0000")
    end
  end

  describe "View struct" do
    it "creates view with content" do
      view = Tea::View.new("Hello World")
      view.content.should eq "Hello World"
    end

    it "creates empty view by default" do
      view = Tea::View.new
      view.content.should eq ""
    end

    it "supports alt screen property" do
      view = Tea::View.new
      view.alt_screen = true
      view.alt_screen?.should be_true
    end

    it "supports report focus property" do
      view = Tea::View.new
      view.report_focus = true
      view.report_focus?.should be_true
    end

    it "supports disable bracketed paste property" do
      view = Tea::View.new
      view.disable_bracketed_paste = true
      view.disable_bracketed_paste?.should be_true
    end

    it "supports mouse mode" do
      view = Tea::View.new
      view.mouse_mode = Tea::MouseMode::CellMotion
      view.mouse_mode.should eq Tea::MouseMode::CellMotion
    end

    it "supports cursor" do
      view = Tea::View.new
      cursor = Tea::Cursor.new(10, 20)
      view.cursor = cursor
      view.cursor.should eq cursor
    end

    it "supports background color" do
      view = Tea::View.new
      view.background_color = Colorful::Color.hex("#0000FF")
      view.background_color.should eq Colorful::Color.hex("#0000FF")
    end

    it "supports foreground color" do
      view = Tea::View.new
      view.foreground_color = Colorful::Color.hex("#00FF00")
      view.foreground_color.should eq Colorful::Color.hex("#00FF00")
    end

    it "supports window title" do
      view = Tea::View.new
      view.window_title = "Test Window"
      view.window_title.should eq "Test Window"
    end
  end

  describe "Cursor" do
    it "initializes with default values" do
      cursor = Tea::Cursor.new
      cursor.x.should eq 0
      cursor.y.should eq 0
      cursor.visible?.should be_true
      cursor.style.should eq Tea::CursorStyle::Block
      cursor.color.should be_nil
    end

    it "initializes with custom values" do
      cursor = Tea::Cursor.new(5, 10, false, Tea::CursorStyle::Bar)
      cursor.x.should eq 5
      cursor.y.should eq 10
      cursor.visible?.should be_false
      cursor.style.should eq Tea::CursorStyle::Bar
      cursor.color.should be_nil
    end

    it "supports custom cursor color" do
      cursor = Tea::Cursor.new(5, 10, false, Tea::CursorStyle::Bar, Colorful::Color.hex("#FF0000"))
      cursor.color.should eq Colorful::Color.hex("#FF0000")
    end

    it "returns position tuple" do
      cursor = Tea::Cursor.new(15, 25)
      cursor.position.should eq({15, 25})
    end
  end

  describe "CursorStyle" do
    it "defines all cursor styles" do
      Tea::CursorStyle::Block.should be_a(Tea::CursorStyle)
      Tea::CursorStyle::BlockBlinking.should be_a(Tea::CursorStyle)
      Tea::CursorStyle::Underline.should be_a(Tea::CursorStyle)
      Tea::CursorStyle::UnderlineBlinking.should be_a(Tea::CursorStyle)
      Tea::CursorStyle::Bar.should be_a(Tea::CursorStyle)
      Tea::CursorStyle::BarBlinking.should be_a(Tea::CursorStyle)
    end
  end

  describe "MouseMode" do
    it "defines all mouse modes" do
      Tea::MouseMode::None.should be_a(Tea::MouseMode)
      Tea::MouseMode::CellMotion.should be_a(Tea::MouseMode)
      Tea::MouseMode::AllMotion.should be_a(Tea::MouseMode)
    end
  end

  describe "KeyboardEnhancements" do
    it "initializes with default values" do
      ke = Tea::KeyboardEnhancements.new
      ke.report_event_types?.should be_false
      ke.report_alternate_keys?.should be_false
      ke.report_all_keys?.should be_false
      ke.report_associated_text?.should be_false
    end

    it "initializes with custom values" do
      ke = Tea::KeyboardEnhancements.new(
        report_event_types: true,
        report_alternate_keys: true,
        report_all_keys: true,
        report_associated_text: true
      )
      ke.report_event_types?.should be_true
      ke.report_alternate_keys?.should be_true
      ke.report_all_keys?.should be_true
      ke.report_associated_text?.should be_true
    end
  end

  describe "ProgressBar" do
    it "initializes with default values" do
      pb = Tea::ProgressBar.new
      pb.value.should eq 0.0
      pb.max.should eq 100.0
      pb.label.should eq ""
    end

    it "initializes with custom values" do
      pb = Tea::ProgressBar.new(50.0, 200.0, "Loading...")
      pb.value.should eq 50.0
      pb.max.should eq 200.0
      pb.label.should eq "Loading..."
    end

    it "calculates percent correctly" do
      pb = Tea::ProgressBar.new(50.0, 100.0)
      pb.percent.should eq 50.0
    end

    it "clamps percent to 0-100" do
      pb = Tea::ProgressBar.new(-10.0, 100.0)
      pb.percent.should eq 0.0

      pb = Tea::ProgressBar.new(150.0, 100.0)
      pb.percent.should eq 100.0
    end
  end
end
