require "earl"
require "earl/scheduler"
require "./store"
require "json"

# Implements an on-disk store for session data.
#
# WARNING: multiple instances must have access to the same `path`.
class Frost::Session::DiskStore < Frost::Session::Store
  include Earl::Artist(Time)

  def initialize(
    path : Path | String,
    @expire_after : Time::Span = 20.minutes,
    schedule_clean_cron : String? = "*/5 * * * *"
  )
    super()
    @path = Path.new(path)
    Earl.scheduler.add(self, cron: schedule_clean_cron) if schedule_clean_cron
  end

  # Called every 5 minutes by Earl::Scheduler to cleanup expired sessions from
  # the disk.
  def call(time : Time) : Nil
    time -= @expire_after

    Dir[@path.join("**", "**")].each do |path|
      if File.file?(path) && File.info(path).modification_time < time
        File.delete(path)
      end
    end
  end

  def find_session(session_id : String) : Session?
    path = __path(Session.hash_id(session_id))
    return unless File.exists?(path)

    if File.info(path).modification_time < @expire_after.ago
      __delete(path)
    else
      Session.new(session_id, __read(path))
    end
  end

  def write_session(session : Session) : Nil
    path = __path(session.private_id)

    unless Dir.exists?(path.dirname)
      path.each_parent do |parent|
        Dir.mkdir(parent) unless Dir.exists?(parent)
      end
    end

    File.write(path, session.to_json)
  end

  def delete_session(session : Session) : Nil
    __delete(__path(session.private_id))
  end

  private def __path(private_id : String) : Path
    @path.join(private_id[-2..-1], private_id[-4..-3], private_id)
  end

  private def __read(path : Path) : Hash(String, String)
    JSON.parse(File.read(path)).as_h.transform_values(&.as_s)
  end

  private def __delete(path : Path) : Nil
    File.delete(path) if File.exists?(path)
  end
end
