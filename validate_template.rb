#!/usr/bin/env ruby

require 'optparse'
require 'open3'
require 'ostruct'
require 'json'
require 'yaml'

options = OpenStruct.new
parser = OptionParser.new do |opts|
  opts.banner = 'Usage: .validate_template [options]'

  opts.on('-p PROFILE', '--profile', 'AWS Credential Profile') do |profile|
    options.profile = profile
  end

  opts.on('-o OUTPUT', '--output', 'CFT format (json or yaml)') do |output|
    options.output = output
  end

  opts.on_tail('-h', '--help', 'print help menu') do
    puts opts
    exit
  end
end
parser.parse!

if options.profile.nil?
  puts 'no profile specified. will look for environment variables. \
  eg. AWS_DEFAULT_PROFILE or AWS_PROFILE'
end

def get_files(path)
  if File.dirname(__FILE__).eql?('.')
    Dir.entries(path).reject { |f| File.directory? f }
       .select { |i| i =~ /\.json|\.yaml|\.yml/ }
  else
    Dir.glob("#{path}/*").select { |i| i =~ /\.json|\.yaml|\.yml/ }
  end
end

def convert_output(file, format)
  puts "converting to #{options.output}"

  case format
  when 'json'
    source = YAML.load_file(file)
    target = JSON.pretty_generate(source)
    ext = '.json'
  when 'yaml'
    source = JSON.parse(IO.read(file))
    target = source.to_yaml
    ext = '.yaml'
  end

  File.open(file, 'w') do |f|
    f.print(target)
  end

  new_file = file.gsub(/(\.\w+)/, ext)
  File.rename(file, new_file)

  check_valid(newFile)
end

def check_valid(file)
  cmd = if options.profile.nil?
          "aws cloudformation validate-template --template-body file://#{file}"
        else
          "aws --profile #{options.profile} cloudformation validate-template \
          --template-body file://#{file}"
        end

  Open3.popen3(cmd) do |_, _, stderr, _|
    puts "#{file}: #{stderr.gets}" while stderr.gets
  end
end

get_files(File.dirname(__FILE__)).each do |file|
  if !options.output.nil?
    if File.extname(file).eql?(".#{options.output}")
      puts 'File does not need converting'
      next
    end
    convert_output(file, options.output)
  else
    check_valid(file)
  end
end
