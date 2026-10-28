# frozen_string_literal: true

# 模拟 Bundle 输出的信任条目接口，不读取或改写本机信任记录。
module Homebrew
  module Trust
    def self.target(name, type:)
      [type, name]
    end
  end

  module Bundle
    module Trust
      def self.entries(entries)
        entries.flat_map do |entry|
          trusted = entry.options[:trusted]
          name = entry.options.fetch(:full_name, entry.name)
          if entry.type == :tap
            if trusted == true
              [[:tap, name]]
            elsif trusted.is_a?(Hash)
              trusted.flat_map do |type, items|
                kind = { formulae: :formula, casks: :cask }.fetch(type, type)
                Array(items).map { |item| [kind, "#{name}/#{item}"] }
              end
            else
              []
            end
          elsif trusted == true && name.count("/") == 2
            [[entry.type == :brew ? :formula : :cask, name]]
          else
            []
          end
        end
      end
    end
  end
end
