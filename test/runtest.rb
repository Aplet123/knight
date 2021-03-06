#!/usr/bin/env ruby
require 'minitest/autorun'

$executable_to_test ||= $*.shift or abort "usage: #$0 <program to test>"

require_relative 'tests/number'
require_relative 'tests/null'
require_relative 'tests/boolean'
require_relative 'tests/string'
require_relative 'tests/block'
require_relative 'tests/identifier'
# require_relative 'tests/function'
