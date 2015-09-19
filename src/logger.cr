require "logger"

module Trail
  def self.logger
    @@logger ||= begin
                   path = File.join(Trail::ROOT, "log", "#{ Trail::ENVIRONMENT }.log")
                   dir_path = File.dirname(path)
                   Dir.mkdir(dir_path) unless Dir.exists?(dir_path)

                   file = File.open(path, "a")
                   file.sync = true

                   logger = Logger.new(file)
                   logger.level = Logger::DEBUG
                   logger
                 end
  end

  def self.logger=(@@logger)
  end
end
