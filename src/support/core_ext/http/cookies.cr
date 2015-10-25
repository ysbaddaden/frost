class HTTP::Cookies
  def delete(name)
    @cookies.delete(name)
  end
end
