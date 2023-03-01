require "minitest/autorun"
require "../../src/view"

module Frost::View::TestHelpers
  def render(view : Frost::View) : String
    view.render(io = IO::Memory.new)
    io.rewind.to_s
  end

  def render(view : Frost::View, &block : -> T) : String forall T
    view.render(io = IO::Memory.new, &block)
    io.rewind.to_s
  end

  def render(io : IO, view : Frost::View) : String
    view.render(io)
    io.rewind.to_s
  end

  def render(io : IO, view : Frost::View, &block : -> T) : String forall T
    view.render(io, &block)
    io.rewind.to_s
  end
end
