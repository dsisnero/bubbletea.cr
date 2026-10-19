require "spec"
require "../src/bubbletea"

# Go parity helper: assert each expected sequence appears in order.
private def assert_in_order(got : String, *wants : String) : Nil
  rest = got
  wants.each do |want|
    idx = rest.index(want)
    raise "expected #{want.inspect} to appear after the previous sequences in #{got.inspect}" unless idx
    rest = rest[(idx + want.size)..]
  end
end

private def render_and_flush(renderer : Tea::CursedRenderer, view : Tea::View) : Nil
  renderer.render(view)
  if err = renderer.flush(false)
    raise err
  end
end

private def new_test_renderer(output : IO::Memory) : Tea::CursedRenderer
  env = Ultraviolet::Environ.new(["TERM=xterm-256color"])
  Tea::CursedRenderer.new(output, env, 80, 24)
end

private def enhancements_view(content : String, report_event_types : Bool) : Tea::View
  ke = Tea::KeyboardEnhancements.new
  ke.report_event_types = report_event_types
  view = Tea::View.new(content)
  view.keyboard_enhancements = ke
  view
end

describe Tea::CursedRenderer do
  describe "kitty keyboard stack" do
    it "restores the stack across stop/start and alt screen switches" do
      # Port of Go test TestCursedRenderer_restoresKittyKeyboardStack.
      output = IO::Memory.new
      renderer = new_test_renderer(output)
      renderer.start

      view = enhancements_view("hello", report_event_types: true)
      push_main = Ansi.push_kitty_keyboard(Ansi::KittyDisambiguateEscapeCodes | Ansi::KittyReportEventTypes)
      pop = Ansi.pop_kitty_keyboard(1)

      render_and_flush(renderer, view)

      # Stop the renderer (as on suspend or ExecProcess) and start it again:
      # close pops the stack entry, start pushes it back.
      if err = renderer.close
        raise err
      end
      renderer.start

      # Enter and leave the alt screen. The terminal keeps a separate Kitty
      # keyboard stack per screen, so each screen gets its own push and pop.
      view.alt_screen = true
      render_and_flush(renderer, view)
      view.alt_screen = false
      render_and_flush(renderer, view)

      if err = renderer.close
        raise err
      end

      got = output.to_s
      # The flags are pushed once per screen activation: the first flush,
      # the flush after the renderer was restarted, and on each screen
      # switch. start() itself does not write to the output.
      got.scan(push_main).size.should eq 4
      # One pop per stop/start cycle and per screen switch: closing pops the
      # current screen's entry, and switching screens pops the entry of the
      # screen being left.
      got.scan(pop).size.should eq 4
      # Every pop must come after a push: the stack is balanced when pushes
      # and pops alternate.
      assert_in_order(got,
        push_main, pop, # close pops the entry pushed by the first flush
        pop,            # entering the alt screen pops the resumed entry
        push_main, pop, # leaving the alt screen
        push_main, pop  # the resumed main screen entry and the final close
      )
      got.should_not contain(Ansi.kitty_keyboard(0, 1))
    end

    it "updates kitty keyboard flags in place" do
      # Port of Go test TestCursedRenderer_updatesKittyKeyboardFlagsInPlace.
      output = IO::Memory.new
      renderer = new_test_renderer(output)

      view = enhancements_view("hello", report_event_types: false)
      render_and_flush(renderer, view)

      # Changing the enhancement flags without switching screens updates the
      # current stack entry in place instead of pushing a new one.
      changed = enhancements_view("hello", report_event_types: true)
      render_and_flush(renderer, changed)

      want_update = Ansi.kitty_keyboard(
        Ansi::KittyDisambiguateEscapeCodes | Ansi::KittyReportEventTypes, 1)
      got = output.to_s
      got.should contain(want_update)
      assert_in_order(got,
        Ansi.push_kitty_keyboard(Ansi::KittyDisambiguateEscapeCodes),
        want_update
      )
      got.should_not contain(Ansi.pop_kitty_keyboard(1))
      got.scan(Ansi.push_kitty_keyboard(0)).size.should be <= 1
    end
  end

  describe "no input" do
    it "does not touch the keyboard protocols" do
      # Go parity: setNoInput disables enhancement requests so the terminal's
      # response cannot leak into the shell after the program exits.
      output = IO::Memory.new
      renderer = new_test_renderer(output)
      renderer.no_input = true
      renderer.start

      render_and_flush(renderer, enhancements_view("hello", report_event_types: true))

      if err = renderer.close
        raise err
      end

      got = output.to_s
      got.should_not contain(Ansi::SetModifyOtherKeys2)
      got.should_not contain(Ansi::ResetModifyOtherKeys)
      got.should_not contain(Ansi::RequestKittyKeyboard)
      got.should_not contain(Ansi.push_kitty_keyboard(0))
      got.should_not contain(Ansi.pop_kitty_keyboard(1))
    end
  end
end
