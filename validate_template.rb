#!/usr/bin/env ruby

require 'optparse'
require 'open3'
require 'ostruct'

@options = OpenStruct.new
parser = OptionParser.new do |opts|
  opts.banner = 'Usage: .validate_template [options]'

  opts.on('-p PROFILE', '--profile', 'AWS Credential Profile') do |profile|
    @options.profile = profile
  end

  opts.on_tail('-h', '--help', 'print help menu') do |help|
    puts opts
    exit
  end
end
parser.parse!

if @options.profile.nil?
  puts 'no profile specified. will look for environment variables. eg. AWS_DEFAULT_PROFILE or AWS_PROFILE'
end

def get_files(path)
  if File.dirname(__FILE__).eql?('.')
    Dir.entries(path).select { |f| !File.directory? f}.select { |i| i =~ /\.json|\.yaml|\.yml/ }
  else
    Dir.glob("#{path}/*").select { |i| i =~ /\.json|\.yaml|\.yml/ }
  end
end

def check_valid(file)
  if @options.profile.nil?
    cmd = "aws cloudformation validate-template --template-body file://#{file}"
  else
    cmd = "aws --profile #{@options.profile} cloudformation validate-template --template-body file://#{file}"
  end

  Open3.popen3(cmd) do |_, _, stderr, _|
    while err = stderr.gets
      puts "#{file}: #{err}"
    end
  end
end

get_files(File.dirname(__FILE__)).each do |file|
  check_valid(file)
end

