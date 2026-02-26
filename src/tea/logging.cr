# Logging for Tea v2-exp
# Ported from Go logging.go
# Provides file-based logging for debugging

module Tea
  # LogOptionsSetter mirrors Go's logging abstraction.
  module LogOptionsSetter
    abstract def set_output(output : IO) : Nil
    abstract def set_prefix(prefix : String) : Nil
  end

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

  # LogToFileWith does allows to call LogToFile with a custom LogOptionsSetter.
  def self.log_to_file_with(path : String, prefix : String, logger : LogOptionsSetter) : File
    file = File.open(path, "a")
    logger.set_output(file)

    final_prefix = prefix
    if final_prefix.size > 0 && !final_prefix[-1].whitespace?
      final_prefix += " "
    end
    logger.set_prefix(final_prefix)

    file
  rescue ex
    raise Exception.new("error opening file for logging: #{ex}")
  end

  # Block-based helper for local custom setup.
  def self.log_to_file_with(path : String, prefix : String, &block : File -> Nil) : File
    file = File.open(path, "a")
    block.call(file)
    file
  rescue ex
    raise Exception.new("error opening file for logging: #{ex}")
  end
end
