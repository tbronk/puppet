# Perform regexp replacement on a string or array of strings.
#
# @example
#
# Get the third octet from the node's IP address:
#
#   $i3 = regsubst($ipaddress,'^(\\d+)\\.(\\d+)\\.(\\d+)\\.(\\d+)$','\\3')
#
# Put angle brackets around each octet in the node's IP address:
#
#   $x = regsubst($ipaddress, /([0-9]+)/, '<\\1>', 'G')
#
# @param target [Array[String]|String]
#      The string or array of strings to operate on.  If an array, the replacement will be
#      performed on each of the elements in the array, and the return value will be an array.
# @param regexp [String|Regexp|Type[Regexp]]
#      The regular expression matching the target string.  If you want it anchored at the start
#      and or end of the string, you must do that with ^ and $ yourself.
# @param replacement [String]
#      Replacement string. Can contain backreferences to what was matched using \\0 (whole match),
#      \\1 (first set of parentheses), and so on.
# @param flags [String]
#      Optional. String of single letter flags for how the regexp is interpreted (E, I, and M cannot be used
#      if pattern is a precompiled regexp):
#        - *E*         Extended regexps
#        - *I*         Ignore case in regexps
#        - *M*         Multiline regexps
#        - *G*         Global replacement; all occurrences of the regexp in each target string will be replaced.  Without this, only the first occurrence will be replaced.
# @param encoding [String]
#      Optional. How to handle multibyte characters when compiling the regexp (must not be used when pattern is a
#      precompiled regexp). A single-character string with the following values:
#        - *N*         None
#        - *E*         EUC
#        - *S*         SJIS
#        - *U*         UTF-8
# @return [Array[String]|String] The result of the substitution. Result type is the same as for the target parameter.
#
Puppet::Functions.create_function(:regsubst) do
  dispatch :regsubst_string do
    param 'Variant[Array[String],String]',  :target
    param 'String',                         :pattern
    param 'String',                         :replacement
    param 'Optional[Pattern[/^[GEIM]*$/]]', :flags
    param "Enum['N','E','S','U']",          :encoding
    arg_count(3, 5)
  end

  dispatch :regsubst_regexp do
    param 'Variant[Array[String],String]',  :target
    param 'Variant[Regexp,Type[Regexp]]',   :pattern
    param 'String',                         :replacement
    param 'Pattern[/^G?$/]',                :flags
    arg_count(3, 4)
  end

  def regsubst_string(target, pattern, replacement, flags = nil, encoding = nil)
    re_flags = 0
    operation = :sub
    if !flags.nil?
      flags.split(//).each do |f|
        case f
        when 'G' then operation = :gsub
        when 'E' then re_flags |= Regexp::EXTENDED
        when 'I' then re_flags |= Regexp::IGNORECASE
        when 'M' then re_flags |= Regexp::MULTILINE
        end
      end
    end
    inner_regsubst(target, Regexp.compile(pattern, re_flags, encoding), replacement, operation)
  end

  def regsubst_regexp(target, pattern, replacement, flags = nil)
    pattern = pattern.pattern if pattern.is_a?(Puppet::Pops::Types::PRegexpType)
    inner_regsubst(target, pattern, replacement, operation = flags == 'G' ? :gsub : :sub)
  end

  def inner_regsubst(target, re, replacement, op)
    target.respond_to?(op) ? target.send(op, re, replacement) : target.collect { |e| e.send(op, re, replacement) }
  end
  private :inner_regsubst
end
