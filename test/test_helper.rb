require 'rubygems'
require 'bundler/setup'

require 'google-apps-provision'

require 'test/unit'

class Test::Unit::TestCase
  
  private
    
    def fixture(name)
      IO.read(File.expand_path("../fixtures/#{name}.xml", __FILE__))
    end
    
end
