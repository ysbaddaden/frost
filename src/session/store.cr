require "../session"

abstract class Frost::Session::Store
  # Searches a session by it's identifier. Returns `nil` if the session doesn't
  # exist or has expired. Returns a Frost::Session otherwise.
  abstract def find_session(session_id : String) : Session?

  # Writes the session. The session must now be findable by it's identifier.
  abstract def write_session(session : Session) : Nil

  # Deletes the session. The session must no longer be findable by it's
  # identifier.
  abstract def delete_session(session : Session) : Nil
end
