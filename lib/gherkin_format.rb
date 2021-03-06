gem 'gherkin', '= 2.12.2'

require 'gherkin/formatter/json_formatter'
require 'gherkin/formatter/pretty_formatter'
require 'gherkin/parser/parser'
require 'stringio'
require 'multi_json'
require 'erb'

# format gherkin files
class GherkinFormat
  def format_string(input, file = 'generated.feature')
    io = StringIO.new
    formatter = Gherkin::Formatter::PrettyFormatter.new(io, true, false)
    parser = Gherkin::Parser::Parser.new(formatter, true)
    parser.parse(input, file, 0)
    io.string.split("\n").map(&:rstrip).join("\n") + "\n"
  end

  def format(file, options = {})
    input = File.read file
    output = format_string input, file
    return if input == output

    File.write(file, output) if options.key? :replace
    raise "File #{file} was not formatted well."
  end

  def render(template, files)
    features = []
    files.each do |file|
      content = File.read file
      features.push to_json(content, file)
    end
    renderer = ERB.new File.read template
    features = Features.new features.flatten
    puts renderer.result features.binding_reference
  end

  def to_json(input, file = 'generated.feature')
    io = StringIO.new
    formatter = Gherkin::Formatter::JSONFormatter.new(io)
    parser = Gherkin::Parser::Parser.new(formatter, true)
    parser.parse(input, file, 0)
    formatter.done
    MultiJson.load io.string
  end

  # container class for erb variable
  class Features
    attr_accessor :features

    def initialize(features)
      @features = features
    end

    def binding_reference
      binding
    end
  end
end
