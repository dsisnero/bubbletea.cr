require "../src/bubbletea"
require "http/client"

URL = "https://charm.sh/"

struct StatusMsg
  include Tea::Msg
  getter status : Int32

  def initialize(@status : Int32)
  end
end

struct ErrMsg
  include Tea::Msg

  def initialize(@err : Exception)
  end

  # Go parity for errMsg.Error()
  def error : String
    @err.message || @err.to_s
  end

  def to_s(io : IO)
    io << error
  end
end

class HttpModel
  include Bubbletea::Model

  def initialize
    @status = 0
    @err = nil.as(ErrMsg?)
  end

  def init : Bubbletea::Cmd?
    check_server
  end

  def update(msg : Tea::Msg)
    case msg
    when Bubbletea::KeyPressMsg
      case msg.keystroke
      when "q", "ctrl+c", "esc"
        {self, Bubbletea.quit}
      else
        {self, nil}
      end
    when StatusMsg
      @status = msg.status
      {self, Bubbletea.quit}
    when ErrMsg
      @err = msg.as(ErrMsg)
      {self, nil}
    else
      {self, nil}
    end
  end

  def view : Bubbletea::View
    s = "Checking #{URL}..."
    if err = @err
      s += "something went wrong: #{err.error}"
    elsif @status != 0
      s += "#{@status} #{status_text(@status)}"
    end
    Bubbletea::View.new(s + "\n")
  end

  private def check_server : Bubbletea::Cmd
    -> : Tea::Msg? do
      client = HTTP::Client.new(URI.parse(URL))
      begin
        res = client.get("/")
        StatusMsg.new(res.status_code)
      rescue ex
        ErrMsg.new(ex)
      ensure
        client.close
      end
    end
  end

  private def status_text(status : Int32) : String
    case status
    when 200 then "OK"
    when 301 then "Moved Permanently"
    when 302 then "Found"
    when 400 then "Bad Request"
    when 401 then "Unauthorized"
    when 403 then "Forbidden"
    when 404 then "Not Found"
    when 500 then "Internal Server Error"
    when 502 then "Bad Gateway"
    when 503 then "Service Unavailable"
    else
      ""
    end
  end
end

program = Bubbletea::Program.new(HttpModel.new)
_model, err = program.run
if err
  STDERR.puts err.message
  exit 1
end
