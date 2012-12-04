require 'test_helper'

class MockTest < Test::Unit::TestCase
  
  def setup
    GoogleApps.connect_with :domain => 'example.com'
    GoogleApps.backend = GoogleApps::Mock
  end
  
  def test_mock_user_entry
    GoogleApps.connection.mock_entry('larry', GoogleApps::User.new(:given_name => 'Larry', :family_name => 'Page'))
    larry = GoogleApps::User.find('larry')
    assert_equal 'Larry', larry.given_name
    assert_equal 'Page', larry.family_name
  end
  
  def test_mock_org_user_entry
    GoogleApps.connection.mock_customer('bigcorp')
    GoogleApps.connection.mock_entry('larry', GoogleApps::OrgUser.new(:org_user_email => 'larry@example.com'))
    larry = GoogleApps::OrgUser.find('larry')
    assert_equal 'larry@example.com', larry.org_user_email
  end
  
  def test_mock_customer
    GoogleApps.connection.mock_customer('bigcorp')
    assert_equal 'bigcorp', GoogleApps.connection.customer_id
  end
  
end
