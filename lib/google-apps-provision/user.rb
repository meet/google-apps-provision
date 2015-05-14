module GoogleApps
  
  # Represents a domain user.
  class User < Entry

    container :users
    
    get_all { |dir| {:api_method => dir.users.list,
                     :parameters => {'domain' => "#{GoogleApps.connection.domain}"}}}
    get_one { |dir, id| {:api_method => dir.users.get,
                         :parameters => {'userKey' => id}}}

    post_new { |dir| {:api_method => dir.users.insert }}
    delete_one { |dir, u| {:api_method => dir.users.delete,
                           :parameters => {'userKey' => u.primary_email}}}
    put_updated { |dir, u| {:api_method => dir.users.patch,
                            :parameters => {'userKey' => u.primary_email}}}

    attributes nil, :id, :primary_email, :is_admin, :agreed_to_terms,
               :suspended, :change_password_at_next_login, :ip_whitelisted, :org_unit_path,
               :password, :hash_function_name

    attributes :name, :given_name, :family_name

    #identity :primary_email
    
    #Set password by sending hashed value.
    def new_password=(value)
      @password = Digest::SHA1.hexdigest(value)
      @hash_function_name = 'SHA-1'
    end

    def user_name
      primary_email.split('@')[0]
    end
  end
  
  # Represents an email nickname.
  # class Nickname < Entry
    
  #   get_all { "#{ENDPOINT}/#{GoogleApps.connection.domain}/nickname/2.0" }
  #   post_new { "#{ENDPOINT}/#{GoogleApps.connection.domain}/nickname/2.0" }
  #   delete_one { |n| "#{ENDPOINT}/#{GoogleApps.connection.domain}/nickname/2.0/#{n.name}" }
    
  #   attributes 'apps:nickname', :name
  #   attributes 'apps:login', :user_name
    
  # end
  
end
