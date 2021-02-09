# frozen_string_literal: true

require 'prism/version'
require 'prism/rails'

module Prism
  class Error < StandardError; end
  # Your code goes here...
end

require File.dirname(__FILE__) + '/prism/prism_model.rb'
Dir[File.dirname(__FILE__) + '/prism/models/*'].sort.each do |model_name|
  require model_name if File.exist?(model_name)
end

require File.dirname(__FILE__) + '/prism/application_helper.rb'
require File.dirname(__FILE__) + '/prism/calculator.rb'
require File.dirname(__FILE__) + '/prism/calculator/website/spec_id_mapper.rb'

Dir[File.dirname(__FILE__) + '/prism/calculator/offset/time/*'].sort.each do |file_name|
  require file_name if File.exist?(file_name)
end

Dir[File.dirname(__FILE__) + '/prism/calculator/*'].sort.each do |file_name|
  next if File.directory?(file_name)

  require file_name if File.exist?(file_name)
end

Dir[File.dirname(__FILE__) + '/prism/calculator/digital/*'].sort.each do |file_name|
  next if File.directory?(file_name)

  require file_name if File.exist?(file_name)
end

Dir[File.dirname(__FILE__) + '/prism/calculator/large_format/*'].sort.each do |file_name|
  next if File.directory?(file_name)

  require file_name if File.exist?(file_name)
end

Dir[File.dirname(__FILE__) + '/prism/officers/*'].sort.each do |file_name|
  require file_name if File.exist?(file_name)
end
