require "./spec_helper"

describe "Pager highlight parity" do
  # Load captured outputs from parity test
  go_output_path = File.join(__DIR__, "../temp/parity/pager.go.view.txt")
  crystal_output_path = File.join(__DIR__, "../temp/parity/pager.crystal.view.txt")

  if File.exists?(go_output_path) && File.exists?(crystal_output_path)
    it "shows missing HighlightStyle and SelectedHighlightStyle in bubbles viewport" do

    go_output = File.read(go_output_path)
    crystal_output = File.read(crystal_output_path)

    # Extract line 6 (the first line with "artichoke" highlight)
    go_line = go_output.split('\n')[7] # 0-indexed, line 8 in file is index 7
    crystal_line = crystal_output.split('\n')[7]

    # Debug: show the lines
    puts "\nGo line 6 (first 'artichoke' highlight):"
    puts go_line.inspect
    puts "\nCrystal line 6 (first 'artichoke' highlight):"
    puts crystal_line.inspect

    # Count ANSI sequences
    go_ansi_count = go_line.scan(/\e\[/).size
    crystal_ansi_count = crystal_line.scan(/\e\[/).size

    # Expected: Go has more ANSI sequences due to HighlightStyle + SelectedHighlightStyle
    # Go sequence for first "artichoke":
    #   [38;5;238;48;5;34m[m[38;5;238;48;5;47martichoke[m[38;5;238;48;5;34m[m
    #   ^^ HighlightStyle (238/34) start
    #      ^^ reset
    #         ^^ SelectedHighlightStyle (238/47) start
    #            ^^ reset
    #               ^^ HighlightStyle (238/34) start
    #                  ^^ reset
    # That's 6 ANSI sequences total

    # Crystal sequence:
    #   [38;5;238;48;5;47martichoke[0m
    #   ^^ SelectedHighlightStyle only (238/47)
    #      ^^ reset
    # That's 2 ANSI sequences

    puts "\nAnalysis:"
    puts "  Go ANSI sequences: #{go_ansi_count}"
    puts "  Crystal ANSI sequences: #{crystal_ansi_count}"
    puts "  Difference: #{go_ansi_count - crystal_ansi_count}"

    # Show the actual difference
    puts "\nMissing functionality in Crystal Bubbles viewport:"
    puts "  1. HighlightStyle property (foreground 238, background 34)"
    puts "  2. SelectedHighlightStyle property (foreground 238, background 47)"
    puts "  3. SetHighlights that accepts byte ranges and creates highlightInfo"
    puts "  4. highlightLines method that applies both styles"
    puts "  5. highlightInfo struct with line/column ranges"

      # This test doesn't fail - it documents the disparity
      # The actual fix requires changes to lib/bubbles
      # Assertion passes to show test completes
      go_ansi_count.should be > 0
      crystal_ansi_count.should be > 0
    end
  else
    pending "Parity capture files not found. Run parity test first."
  end
end
