require 'rubygems'
require 'shoulda'
require 'sample_jobs'

$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'resque_unit'
