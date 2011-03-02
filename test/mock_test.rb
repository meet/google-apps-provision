require 'test_helper'

class MockTest < Test::Unit::TestCase
  
  def setup
    GoogleApps.connect_with :domain => 'example.com'
    GoogleApps.backend = GoogleApps::Mock
  end
  
  def test_mock_entry
    GoogleApps.connection.mock_entry('larry', GoogleApps::User.new(:given_name => 'Larry', :family_name => 'Page'))
    larry = GoogleApps::User.find('larry')
    assert_equal 'Larry', larry.given_name
    assert_equal 'Page', larry.family_name
  end
  
end
