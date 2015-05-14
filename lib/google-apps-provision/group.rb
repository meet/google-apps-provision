module GoogleApps
  
  # Represents a group.
  class Group < Entry

    container :groups
    
    get_all { |dir| {:api_method => dir.groups.list,
                     :parameters => {'domain' => "#{GoogleApps.connection.domain}"}}}
    get_one { |dir, id| {:api_method => dir.groups.get,
                         :parameters => {'groupKey' => id}}}
    
    post_new { |dir| {:api_method => dir.users.insert }}
    delete_one { |dir, g| {:api_method => dir.groups.delete,
                           :parameters => {'groupKey' => g.email}}}
    put_updated { |dir, g| {:api_method => dir.groups.patch,
                            :parameters => {'groupKey' => g.email}}}

    attributes nil, :id, :email, :name, :description, :admin_created
    
    # GroupMember class for this Group.
    def members
      clazz = Class.new(GroupMember)
      clazz.class_exec(email) do |group_id|
        get_all { |dir| {:api_method => dir.members.list,
                         :parameters => {'groupKey' => group_id}}}
        post_new { |dir| {:api_method => dir.members.insert,
                          :parameters => {'groupKey' => group_id}}}
        delete_one { |dir, m| {:api_method => dir.members.delete,
                               :parameters => {'groupKey' => group_id,
                                               'memberKey' => m.email}}}
      end
      clazz
    end

    def owners
      members.all.reject { |member| member.role != "OWNER"}
    end
  end
  
  # Represents a group membership. See +Group.members+.
  class GroupMember < Entry

    container :members
    
    attributes nil, :email, :role, :id, :type
    
  end
  
end
