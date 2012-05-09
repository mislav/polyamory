require 'forwardable'

module Polyamory
  # Internal: Represents a single command to run.
  class Command
    def initialize cmd
      @args = Array(cmd)
      yield self if block_given?
    end

    extend Forwardable
    def_delegators :@args, :<<, :concat

    def to_exec
      @args.map {|a| a.to_s }
    end

    def to_s
      to_exec.join(' ')
    end
  end
end
