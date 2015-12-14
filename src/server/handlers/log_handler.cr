require "http/server"

module Frost::Server
  class LogHandler < HTTP::Handler
    def call(request)
      time = Time.now
      call_next(request).tap do |response|
        elapsed = elapsed_text(Time.now - time)
        Frost.logger.info "#{ request.method } #{ request.path.inspect } #{ response.status_code } (#{ elapsed })"
      end
    end

    private def elapsed_text(elapsed)
      if (minutes = elapsed.total_minutes) >= 1
        return "#{ minutes.round(2) }m"
      end

      if (seconds = elapsed.total_seconds) >= 1
        return "#{ seconds.round(2) }s"
      end

      if (millis = elapsed.total_milliseconds) >= 1
        return "#{ millis.round(2) }ms"
      end

      "#{ (millis * 1000).round(2) }µs"
    end
  end
end
