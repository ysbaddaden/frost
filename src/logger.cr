require "logger"

module Trail
  DEFAULT_LOGGER_FORMATTER = Logger::Formatter.new do |severity, datetime, _, message, io|
    io << severity[0] << ", [" << datetime << " #" << Process.pid << "] " << message
  end

  def self.logger
    @@logger ||= begin
                   path = File.join(Trail.root, "log", "#{ Trail.environment }.log")
                   dir_path = File.dirname(path)
                   Dir.mkdir(dir_path) unless Dir.exists?(dir_path)

                   file = File.open(path, "a")
                   file.sync = true

                   logger = Logger.new(file)
                   logger.level = Logger::DEBUG
                   logger.formatter = DEFAULT_LOGGER_FORMATTER
                   logger
                 end
  end

  def self.logger=(@@logger)
  end
end
