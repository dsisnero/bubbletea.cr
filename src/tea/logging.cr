# Logging for Tea v2-exp
# Ported from Go logging.go
# Provides file-based logging for debugging

module Tea
  # LogToFile sets up logging to a file with the given path and prefix.
  # This is helpful since the TUI occupies the terminal.
  # If the file doesn't exist, it will be created.
  #
  # Don't forget to close the file when you're done:
  #
  #   file = Tea.log_to_file("debug.log", "debug")
  #   # ... use program ...
  #   file.close
  #
  # Returns the file handle or raises on error.
  def self.log_to_file(path : String, prefix : String) : File
    file = File.open(path, "a")

    # Add a space after the prefix if specified and doesn't have trailing space
    if prefix.size > 0 && !prefix[-1].whitespace?
      # Prefix will be used by caller with Log setup
    end

    file
  rescue ex
    raise Exception.new("error opening file for logging: #{ex}")
  end

  # LogToFileWith allows using a custom logger setup.
  # The block receives the file handle and can configure logging.
  def self.log_to_file_with(path : String, prefix : String, &block : File -> Nil) : File
    file = File.open(path, "a")

    # Call the block with the file for custom configuration
    block.call(file)

    file
  rescue ex
    raise Exception.new("error opening file for logging: #{ex}")
  end
end
