re = /^(?:(?:\d+-\d+-\d+\s*)+(?:\d+:\d+)?|\w{3}\s+.+\d{4})\s+([^\d<\(]+)(?:[\(<](.+)[\)>])?+/

FIXES = {
  "Klaus Kaempf":       "Klaus Kämpf",
  "david d `zoo' zuhn": "david d 'zoo' zuhn",
  "david d`zoo' zuhn":  "david d 'zoo' zuhn",
}

REPLACES = {
  "\"u": "ü",
  "\"a": "ä",
  "\"o": "ö",
}

ret = []
File.open("#{File.dirname(__FILE__)}/../riscv-gnu-toolchain/riscv-binutils/ChangeLog", "r") do |f|
  f.readlines.each do |line|
    matches = re.match line
    if matches
      name = matches[1].strip
      if name.include? "@"
        if matches[2]
          name = matches[2].strip
        end
      end
      REPLACES.each do |a, b|
        name.sub!(a.to_s, b.to_s)
      end
      if FIXES[name.intern]
        name = FIXES[name.intern]
      end
      ret << name
    elsif /^[\w\d]/.match line
    end
  end
end

ret.uniq!

require 'json'
puts(ret.to_json)

