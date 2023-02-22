module Frost
  struct CookieOptions
    def initialize(*,
      @path : String? = "/",
      @expires : Time? = nil,
      @domain : String? = nil,
      @secure : Bool? = nil,
      @http_only : Bool = false,
      @samesite : HTTP::Cookie::SameSite? = :lax,
      @extension : String? = nil,
      @max_age : Time::Span? = nil,
    )
    end

    # :nodoc:
    def to_kwargs : NamedTuple
      {
        path: @path,
        expires: @expires,
        domain: @domain,
        secure: @secure,
        http_only: @http_only,
        samesite: @samesite,
        extension: @extension,
        max_age: @max_age,
      }
    end
  end
end
