module Frost::Integration::TestRequests
  def options(resource : String, **options) : Nil
    process("OPTIONS", resource, **options)
  end

  def head(resource : String, **options) : Nil
    process("HEAD", resource, **options)
  end

  def get(resource : String, **options) : Nil
    process("GET", resource, **options)
  end

  def post(resource : String, **options) : Nil
    process("POST", resource, **options)
  end

  def put(resource : String, **options) : Nil
    process("POST", resource, **options)
  end

  def patch(resource : String, **options) : Nil
    process("PATCH", resource, **options)
  end

  def delete(resource : String, **options) : Nil
    process("DELETE", resource, **options)
  end

  def follow_redirect!(**options) : Nil
    assert_includes 300..399, response.status_code, -> {
      "Expected redirect but got #{response.status} (#{response.status_code})"
    }
    http_method =
      if {307, 308}.includes?(response.status_code)
        default_session.request.not_nil!.method
      else
        "GET"
      end
    process(http_method, response.headers["location"], **options)
  end
end
