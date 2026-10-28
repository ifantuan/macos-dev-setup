# frozen_string_literal: true

require "json"

# 仅模拟 Homebrew 的外部接口；清单通过 Ruby 求值，保留引号、选项和条件语句的语义。
# 安装清单完全来自测试数据，不读取真实 Cellar、Caskroom 或信任文件。
module Homebrew
  module Bundle
    Entry = Struct.new(:type, :name, :options)

    class Brewfile
      attr_reader :entries

      def self.read(file:)
        parser = new
        parser.instance_eval(File.read(file), file)
        parser
      end

      def initialize
        @entries = []
      end

      def brew(name, options = {})
        @entries << Entry.new(:brew, name, options)
      end

      def cask(name, options = {})
        @entries << Entry.new(:cask, name.split("/").last, options.merge(full_name: name))
      end

      def tap(name, options = {})
        @entries << Entry.new(:tap, name, options)
      end
    end
  end
end

class Formula
  def self.installed
    JSON.parse(ENV.fetch("TEST_FORMULAE", "[]")).map { |name| Struct.new(:full_name).new(name) }
  end
end
