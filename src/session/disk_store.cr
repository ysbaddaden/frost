require "earl"
require "earl/scheduler"
require "./store"
require "json"

# Implements an on-disk store for session data.
#
# WARNING: multiple instances must have access to the same `path` on disk!
class Frost::Session::DiskStore < Frost::Session::Store
  include Earl::Artist(Time)

  class ValidationError < Exception; end

  def initialize(
    path : Path | String,
    @expire_after : Time::Span = 20.minutes,
    schedule_clean_cron : String? = "*/5 * * * *"
  )
    super()
    @path = Path.new(path)
    __validate!
    Earl.scheduler.add(self, cron: schedule_clean_cron) if schedule_clean_cron
  end

  # Called every 5 minutes by Earl::Scheduler to cleanup expired sessions from
  # the disk.
  def call(time : Time) : Nil
    time -= @expire_after

    Dir.glob(@path.join("**", "**")) do |path|
      if (info = File.info?(path)) && info.file? && info.modification_time < time
        File.delete?(path)
      end
    end
  end

  def find_session(session_id : String) : Session?
    path = __path(Session.hash_id(session_id))
    return unless info = File.info?(path)

    if info.modification_time < @expire_after.ago
      File.delete?(path)
      nil
    elsif data = __read(path)
      Session.new(session_id, data)
    end
  end

  def write_session(session : Session) : Nil
    path = __path(session.private_id)

    unless Dir.exists?(path.dirname)
      path.each_parent do |parent|
        Dir.mkdir(parent) unless Dir.exists?(parent)
      rescue File::AlreadyExistsError
      end
    end

    File.write(path, session.to_json)
  end

  def extend_session(session : Session) : Nil
    path = __path(session.private_id)
    File.utime(Time.utc, Time.utc, path) if File.exists?(path)
  rescue File::NotFoundError
  end

  def delete_session(session : Session) : Nil
    path = __path(session.private_id)
    File.delete?(path)
  end

  private def __path(private_id : String) : Path
    @path.join(private_id[-2..-1], private_id[-4..-3], private_id)
  end

  private def __read(path)
    File
      .open(path, "r") { |io| JSON.parse(io) }
      .as_h
      .transform_values(&.as_s)
  rescue File::NotFoundError
  end

  private def __validate! : Nil
    unless Dir.exists?(@path)
      raise ValidationError.new("The path at #{@path} isn't a directory.")
    end
    unless File.writable?(@path)
      raise ValidationError.new("The path at #{@path} isn't writable. You might be missing write permissions.")
    end
  end
end
