module Vimrunner
  module Driver
    class Abstract
      attr_reader :path

      def initialize(path)
        @path = path
      end

      def spawn(command)
        raise NotImplementedError, "must be defined in a subclass."
      end

      def ==(other)
        other.is_a?(Driver::Abstract) && path == other.path
      end
    end
  end
end
