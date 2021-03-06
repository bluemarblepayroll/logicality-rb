# frozen_string_literal: true

#
# Copyright (c) 2018-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

require_relative 'lexer/lexer'
require_relative 'parser/parser'
require_relative 'interpreter/interpreter'

# Module that defines the main class-level API for this library.
module Logicality
  class << self
    def evaluate(expression, input = nil, resolver = nil)
      node        = get(expression)
      wrapper     = resolver_wrapper(input, resolver)
      interpreter = Interpreter::SimpleInterpreter.new(wrapper)

      interpreter.visit(node)
    end

    private

    def resolver_wrapper(input, resolver)
      if resolver
        ->(value) { resolver.call(value, input) }
      else
        ->(value) { object_resolver.call(value, input) }
      end
    end

    def object_resolver
      lambda do |value, input|
        return false unless input

        if input.respond_to?(value)
          !!input.send(value)
        elsif input.respond_to?(:[])
          !!input[value]
        else
          false
        end
      end
    end

    def cache
      @cache ||= {}
    end

    def set(expression, node)
      cache[expression] ||= node
    end

    def get(expression)
      return cache[expression] if cache[expression]

      lexer   = Lexer::RegexpLexer.new(expression)
      parser  = Parser::SimpleParser.new(lexer)

      set(expression, parser.parse)
    end
  end
end
