require "earl"
require "earl/scheduler"
require "./store"

# Implements an in-memory store for session data.
#
# WARNING: The sessions are tied to the current process. All sessions will be
# lost when the process is restarted.
class Frost::Session::MemoryStore < Frost::Session::Store
  include Earl::Artist(Time)

  def initialize(@expire_after : Time::Span = 20.minutes, schedule_clean_cron : String? = "*/5 * * * *")
    super()
    @mutex = Mutex.new(:unchecked)
    @map = {} of String => {Time, Session}
    Earl.scheduler.add(self, cron: schedule_clean_cron) if schedule_clean_cron
  end

  # Called every 5 minutes by Earl::Scheduler to cleanup expired sessions from
  # the in-memory hashmap.
  def call(time : Time) : Nil
    time -= @expire_after

    @mutex.synchronize do
      @map.reject! { |_, (updated_at, _)| updated_at < time }
    end
  end

  def find_session(session_id : String) : Session?
    private_id = Session.hash_id(session_id)
    return unless entry = @mutex.synchronize { @map[private_id]? }
    updated_at, session = entry

    if updated_at < @expire_after.ago
      delete_session(session)
    else
      session
    end
  end

  def write_session(session : Session) : Nil
    @mutex.synchronize { @map[session.private_id] = {Time.utc, session} }
  end

  def delete_session(session : Session) : Nil
    @mutex.synchronize { @map.delete(session.private_id) }
  end
end
