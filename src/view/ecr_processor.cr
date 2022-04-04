require "compiler/crystal/syntax/*"
require "ecr/processor"

module Frost
  class View
    # nodoc
    class RewriteInstanceVars < Crystal::Transformer
      # Rewrites `@ivar` into `controller.@ivar.not_nil!`.
      def transform(node : Crystal::InstanceVar)
        controller = Crystal::Call.new(nil, "controller").at(node)
        ivar = Crystal::ReadInstanceVar.new(controller, node.name).at(node)
        Crystal::Call.new(ivar, "not_nil!").at(node)
      end
    end

    def self.ecr_processor(filename, buffer_name = nil)
      source = ECR.process_file(filename, buffer_name || ECR::DefaultBufferName)
      ast = Crystal::Parser.parse(source)
      ast.transform(RewriteInstanceVars.new)
    end
  end
end
