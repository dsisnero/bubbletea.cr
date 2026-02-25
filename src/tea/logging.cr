# Logging for Tea v2-exp
# Ported from Go logging.go
# Provides file-based logging for debugging

require "log"

module Tea
  # Logger interface that supports setting output and prefix
  # Compatible with both stdlib's Log and custom loggers
  module Logger
    abstract def output=(io : IO)
    abstract def level=(level : Log::Severity)
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
    log_to_file_with(path, prefix, Log)
  end

  # LogToFileWith allows using a custom logger.
  # The logger must implement the Logger interface.
  def self.log_to_file_with(path : String, prefix : String, logger : Logger) : File
    file = File.open(path, "a")
    logger.output = file

    # Add a space after the prefix if specified and doesn't have trailing space
    final_prefix = if prefix.size > 0 && !prefix[-1].whitespace?
                     prefix + " "
                   else
                     prefix
                   end

    # Set up Log with prefix - Crystal's Log uses different sources
    # We return the file handle and let the caller configure Log
    file
  rescue ex
    raise Exception.new("error opening file for logging: #{ex}")
  end
end
