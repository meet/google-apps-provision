require 'test_helper'

class UserTest < Test::Unit::TestCase
  
  def setup
    GoogleApps.connect_with :domain => 'example.com'
    GoogleApps.backend = GoogleApps::Mock
  end
  
  def test_get
    GoogleApps.connection.mock(:GET,
                               'https://apps-apis.google.com/a/feeds/example.com/user/2.0/sergey',
                               fixture(:sergey))
    sergey = GoogleApps::User.find('sergey')
    assert_equal 'Sergey', sergey.given_name
    assert_equal 'Brin', sergey.family_name
    assert_equal 'sergey', sergey.user_name
    assert ! sergey.admin
    assert ! sergey.suspended
    assert sergey.agreed_to_terms
  end
  
end