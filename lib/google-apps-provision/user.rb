module GoogleApps
  
  # Represents a domain user.
  class User < Entry
    
    get_all { "#{ENDPOINT}/#{GoogleApps.connection.domain}/user/2.0" }
    get_one { |id| "#{ENDPOINT}/#{GoogleApps.connection.domain}/user/2.0/#{id}" }
    post_new { "#{ENDPOINT}/#{GoogleApps.connection.domain}/user/2.0" }
    put_updated { |u| "#{ENDPOINT}/#{GoogleApps.connection.domain}/user/2.0/#{u.user_name}" }
    
    attributes 'apps:login', :user_name, :admin, :suspended, :agreed_to_terms, :change_password_at_next_login, :ip_whitelisted
    attributes 'apps:name', :given_name, :family_name
    attributes 'apps:quota', :limit
    
    identity :user_name
    
  end
  
  # Represents an email nickname.
  class Nickname < Entry
    
    get_all { "#{ENDPOINT}/#{GoogleApps.connection.domain}/nickname/2.0" }
    post_new { "#{ENDPOINT}/#{GoogleApps.connection.domain}/nickname/2.0" }
    delete_one { |n| "#{ENDPOINT}/#{GoogleApps.connection.domain}/nickname/2.0/#{n.name}" }
    
    attributes 'apps:nickname', :name
    attributes 'apps:login', :user_name
    
  end
  
end
