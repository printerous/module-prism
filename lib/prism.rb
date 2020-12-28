require 'prism/version'
require 'prism/rails'

module Prism
  class Error < StandardError; end
  # Your code goes here...
end

require File.dirname(__FILE__) + '/prism/prism_model.rb'
Dir[File.dirname(__FILE__) + '/prism/models/*'].each do |model_name|
  require model_name if File.exist?(model_name)
end
