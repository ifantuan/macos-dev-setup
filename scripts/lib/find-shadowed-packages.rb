# frozen_string_literal: true

# 用法：brew ruby scripts/lib/find-shadowed-packages.rb <Brewfile>
# 列出清单保留但没有为其来源保留信任的第三方包，每行一个“类型<TAB>完整名称”。
# 清单及信任声明均由 Bundle 解析；只读检查，不创建或重置信任记录。
require "bundle/brewfile"
require "bundle/trust"
require "cask/caskroom"

entries = Homebrew::Bundle::Brewfile.read(file: ARGV.fetch(0)).entries
declared = entries.select { |entry| [:brew, :cask].include?(entry.type) }.map do |entry|
  [entry.type, entry.name]
end
trusted = Homebrew::Bundle::Trust.entries(entries)

installed = Formula.installed.map { |formula| [:brew, formula.full_name] } +
            Cask::Caskroom.casks.map { |cask| [:cask, cask.full_name] }

installed.each do |type, full_name|
  next unless full_name.include?("/")

  token = full_name.split("/").last
  # Bundle 已将 cask 条目名称转为短 token；完整来源仍在 options 中交给信任规则核对。
  next unless declared.include?([type, full_name]) || declared.include?([type, token])

  trust_type = type == :brew ? :formula : :cask
  tap_name = full_name.rpartition("/").first
  # 使用与 Homebrew 清理相同的规范化规则，保留按包、按 tap 授权以及自定义远端语义。
  next if trusted.include?(Homebrew::Trust.target(full_name, type: trust_type)) ||
          trusted.include?(Homebrew::Trust.target(tap_name, type: :tap))

  puts "#{type}\t#{full_name}"
end
