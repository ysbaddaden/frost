require "earl/scheduler"
require "./store"

# Implements an in-memory store for session data.
#
# The sessions are tied to the current process. They are only available in this
# process. All sessions will be lost when the process is restarted.
class Frost::Session::MemoryStore < Frost::Session::Store
  include Earl::Artist(Time)

  def initialize(@expire_after : Time::Span = 20.minutes)
    super()
    @mutex = Mutex.new(:unchecked)
    @map = {} of String => Session
    Earl.scheduler.add(self, cron: "*/5 * * * *")
  end

  # Called every 5 minutes by Earl::Scheduler to cleanup expired sessions from
  # the in-memory hashmap.
  def call(time : Time) : Nil
    time -= @expire_after

    @mutex.synchronize do
      @map.reject! { |_, session| session.updated_at < time }
    end
  end

  def find_session(session_id : String) : Session?
    return unless session = @mutex.synchronize { @map[session_id]? }
    return delete_session(session) if session.updated_at < @expire_after.ago

    session.touch!
    session
  end

  private def write_session(session : Session) : Nil
    @mutex.synchronize { @map[session.id] = session }
  end

  private def delete_session(session : Session) : Nil
    @mutex.synchronize { @map.delete(session.id) }
  end
end
