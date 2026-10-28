# frozen_string_literal: true

require "json"

module Cask
  module Caskroom
    def self.casks
      JSON.parse(ENV.fetch("TEST_CASKS", "[]")).map { |name| Struct.new(:full_name).new(name) }
    end
  end
end
