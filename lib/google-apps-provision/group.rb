module GoogleApps
  
  # Represents a group.
  class Group < Entry
    
    get_all { "#{ENDPOINT}/group/2.0/#{GoogleApps.connection.domain}" }
    get_one { |id| "#{ENDPOINT}/group/2.0/#{GoogleApps.connection.domain}/#{id}" }
    post_new { "#{ENDPOINT}/group/2.0/#{GoogleApps.connection.domain}" }
    put_updated { |g| "#{ENDPOINT}/group/2.0/#{GoogleApps.connection.domain}/#{g.group_id}" }
    
    properties :group_id, :group_name, :description, :email_permission
    
    # GroupMember class for this Group.
    def members
      clazz = Class.new(GroupMember)
      clazz.class_exec(group_id) do |group_id|
        get_all { "#{ENDPOINT}/group/2.0/#{GoogleApps.connection.domain}/#{group_id}/member?includeSuspendedUsers=true" }
        post_new { "#{ENDPOINT}/group/2.0/#{GoogleApps.connection.domain}/#{group_id}/member" }
        delete_one { |m| "#{ENDPOINT}/group/2.0/#{GoogleApps.connection.domain}/#{group_id}/member/#{m.member_id}" }
      end
      clazz
    end
    
  end
  
  # Represents a group membership. See +Group.members+.
  class GroupMember < Entry
    
    properties :member_id, :member_type, :direct_member
    
  end
  
end