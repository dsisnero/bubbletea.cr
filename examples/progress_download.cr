require "../lib/bubbles/src/bubbles"
require "http/client"
require "option_parser"
require "uri"

PADDING = 2
MAX_WIDTH = 80

PROGRESS_DOWNLOAD_HELP_STYLE = Lipgloss::Style.new.foreground("#626262")

class ProgressMsg
  include Tea::Msg
  getter ratio : Float64

  def initialize(@ratio : Float64)
  end
end

class ProgressErrMsg
  include Tea::Msg
  getter err : Exception

  def initialize(@err : Exception)
  end
end

class ProgressWriter
  getter total : Int32
  getter downloaded : Int32

  def initialize(@total : Int32, @file : File, @reader : IO, @on_progress : Proc(Float64, Nil)?)
    @downloaded = 0
  end

  def start
    buffer = Bytes.new(8192)
    loop do
      read = @reader.read(buffer)
      break if read == 0

      @file.write(buffer[0, read])
      @downloaded += read

      if @total > 0
        @on_progress.try &.call(@downloaded.to_f / @total.to_f)
      end
    end
  rescue ex
    ProgressDownloadModel.program.try &.send(ProgressErrMsg.new(ex))
  end
end

class ProgressDownloadModel
  include Bubbletea::Model

  @@program : Bubbletea::Program? = nil

  property pw : ProgressWriter?
  property progress : Bubbles::Progress::Model
  property err : Exception?

  def self.program : Bubbletea::Program?
    @@program
  end

  def self.program=(program : Bubbletea::Program?)
    @@program = program
  end

  def initialize(@pw : ProgressWriter? = nil, @progress = Bubbles::Progress.new(Bubbles::Progress.with_default_blend))
    @err = nil
  end

  def init : Bubbletea::Cmd?
    nil
  end

  def update(msg : Tea::Msg)
    case msg
    when Bubbletea::KeyPressMsg
      return {self, Bubbletea.quit}
    when Bubbletea::WindowSizeMsg
      @progress.set_width(msg.width - PADDING * 2 - 4)
      if @progress.width > MAX_WIDTH
        @progress.set_width(MAX_WIDTH)
      end
      return {self, nil}
    when ProgressErrMsg
      @err = msg.err
      return {self, Bubbletea.quit}
    when ProgressMsg
      cmds = [] of Tea::Cmd?
      if msg.ratio >= 1.0
        cmds << Bubbletea.sequence(final_pause, Bubbletea.quit)
      end
      cmds << @progress.set_percent(msg.ratio)
      return {self, Bubbletea.batch(cmds)}
    when Bubbles::Progress::FrameMsg
      @progress, cmd = @progress.update(msg)
      return {self, cmd}
    end

    {self, nil}
  end

  def view : Bubbletea::View
    if err = @err
      return Bubbletea::View.new("Error downloading: #{err.message}\n")
    end

    pad = " " * PADDING
    Bubbletea::View.new("\n" +
      pad + @progress.view + "\n\n" +
      pad + PROGRESS_DOWNLOAD_HELP_STYLE.render("Press any key to quit"))
  end

  private def final_pause : Bubbletea::Cmd
    Bubbletea.tick(750.milliseconds, ->(_t : Time) { nil.as(Tea::Msg?) })
  end
end

unless ENV["BUBBLETEA_EXAMPLE_DISABLE_MAIN"]? == "1"
  url = ""
  OptionParser.parse do |parser|
    parser.banner = "Usage: progress_download --url URL"
    parser.on("--url URL", "url for the file to download") { |value| url = value }
  end

  if url.empty?
    STDERR.puts "Usage: progress_download --url URL"
    exit 1
  end

  uri = URI.parse(url)
  response = HTTP::Client.get(uri)
  unless response.status.ok?
    STDERR.puts "could not get response receiving status of #{response.status.code} for url: #{url}"
    exit 1
  end

  body = response.body
  content_length = body.bytesize
  if content_length <= 0
    STDERR.puts "can't parse content length, aborting download"
    exit 1
  end

  filename = File.basename(uri.path)
  file = File.new(filename, "w")

  model = ProgressDownloadModel.new
  program = Bubbletea::Program.new(model)
  ProgressDownloadModel.program = program

  writer = ProgressWriter.new(
    content_length,
    file,
    IO::Memory.new(body),
    ->(ratio : Float64) { program.send(ProgressMsg.new(ratio)) }
  )

  spawn do
    begin
      writer.start
    ensure
      file.close
    end
  end

  _model, err = program.run
  if err
    STDERR.puts "error running program: #{err.message}"
    exit 1
  end
end
