require 'rubygems'
require 'bundler'

Bundler.require

require './sofia_apk_builder'

FileUtils.mkdir_p 'log' unless File.exists?('log')
log = File.new("log/sinatra.log", "a")

$stdout.reopen(log)
$stderr.reopen(log)

run SofiaAPKBuilder
