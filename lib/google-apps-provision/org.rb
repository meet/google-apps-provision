module GoogleApps
  
  # Represents an organization membership.
  class OrgUser < Entry
    
    get_all { "#{ENDPOINT}/orguser/2.0/#{GoogleApps.connection.customer_id}?get=all" }
    put_updated { |u| "#{ENDPOINT}/orguser/2.0/#{GoogleApps.connection.customer_id}/#{u.org_user_email}" }
    
    properties :org_user_email, :org_unit_path
    
    identity :org_user_email
    
    # Also sets URL, since Org User entries are never created, only updated.
    def org_user_email=(value)
      @org_user_email = value
      @url = "#{ENDPOINT}/orguser/2.0/#{GoogleApps.connection.customer_id}/#{value}"
    end
    
  end
  
  # Represents an organization unit.
  class OrgUnit < Entry
    
    get_all { "#{ENDPOINT}/orgunit/2.0/#{GoogleApps.connection.customer_id}?get=all" }
    get_one { |path| "#{ENDPOINT}/orgunit/2.0/#{GoogleApps.connection.customer_id}/#{path}" }
    
    properties :name, :description, :org_unit_path, :parent_org_unit_path, :block_inheritance
    
    identity :org_unit_path
    
  end
  
end
