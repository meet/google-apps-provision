module GoogleApps
  @@debug_val = nil
  def self.debug_val
    @@debug_val
  end

  def self.debug_val=(val)
    @@debug_val = val
  end
  
  # Base class for feed entries.
  class Entry
    
    # Find all entries of this type.
    def self.all
      result = GoogleApps.connection.execute(get_all_request)
      raw_data = result.data.send(get_container)
      while result.next_page_token
        request = result.next_page
        result = GoogleApps.connection.execute(request)
        raw_data += result.data.send(get_container)
      end
      raw_data.map {|elt| self.new.load(elt)}
    end
    
    # Find the entry with this identifier.
    def self.find(identifier)
      result = GoogleApps.connection.execute(get_one_request(identifier))
      return self.new.load(result.data)
    end
    
    def exists_remotely?
      @exists_remotely
    end

    def exist_remotely
      @exists_remotely = true
    end
    
    def initialize(attributes={})
      @exists_remotely = false
      @loaded = {}
      @deleted = false
      attributes.each do |attrib, value|
        send("#{attrib}=", value)
      end
    end
    
    # Load in fields from XML.
    def load(entry)
      @exists_remotely = true
      self.class.attribute_tags_names.each_pair do |key, values|
        if key == ''
          obj = entry
        else
          obj = entry.send(key)
        end
        values.each do |attr_name|
          begin
            value = obj.send("#{attr_name.camelcase(:lower)}")
            send("#{attr_name}=", value)
            @loaded[attr_name] = value
          rescue
          end
        end
      end
      return self
    end
    
    # Update multiple fields.
    def update(attributes)
      attributes.each do |attrib, value|
        send("#{attrib}=", value)
      end
    end
    
    # Delete this entry (when saved).
    def delete
      @deleted = true
      # XXX BUG: prevent further modification
    end
    
    # Has this entry been deleted?
    def deleted?
      @deleted
    end
    
    # Fields of this entry that have changed since +load+ing.
    def changed
      fields = []
      ( self.class.attribute_tags_names.values.flatten + self.class.property_names - self.class.identity_names).each do |name|
        fields << name if send(name) != @loaded[name]
      end
      return fields
    end
    
    # Is this entry newly created, deleted, or changed?
    def changed?
      return true if deleted?
      return true if exists_remotely? == false
      return ! changed.empty?
    end
    
    # Save this entry, either by creating, deleting, or updating.
    def save
      if deleted?
        GoogleApps.connection.execute(self.class.delete_one_request(self))
      elsif exists_remotely? == false
        request = self.class.post_new_request
        request[:body_object] = package_changes
        GoogleApps.connection.execute(request)
        exist_remotely
      elsif ! changed.empty?
        request = self.class.put_updated_request(self)
        request[:body_object] = package_changes
        GoogleApps.connection.execute(request)
      end
      self
    end

    def package_changes
      changed_attributes = changed
      body = {}

      self.class.attribute_tags_names.each_pair do |parent_name, children|
        if parent_name.empty?
          my_map = body
        else
          my_map = {}
        end
        children.each do |attr_name|
          if changed_attributes.include? attr_name
            my_map[attr_name.camelcase(:lower)] = self.send(attr_name)
          end
        end
        if (! parent_name.empty?) and (! my_map.empty?)
          body[parent_name.camelcase(:lower)] = my_map
        end
      end
      body
    end

    protected
      
      # For defining subclasses
      
      # Set the URL used to GET all instances.
      def self.get_all(&block)
        class_variable_set(:@@get_all_url_proc, block)
      end
      
      # Set the URL used to GET one instance.
      def self.get_one(&block) # :yields: identifier
        class_variable_set(:@@get_one_url_proc, block)
      end
      
      # Set the URL used to POST a new instance.
      def self.post_new(&block)
        class_variable_set(:@@post_new_url_proc, block)
      end
      
      # Set the URL used to PUT updates to an instance.
      def self.put_updated(&block) # :yields: entry
        class_variable_set(:@@put_updated_url_proc, block)
      end
      
      # Set the URL used to DELETE an instance
      def self.delete_one(&block) # :yields: entry
        class_variable_set(:@@delete_one_url_proc, block)
      end
      
      # Declare fields serialized as +<apps:_tag_ _name1_='_val1_' _name2_='_val2_' .../>+.
      def self.attributes(tag, *attributes)
        attribute_tags_names[tag.to_s] = attributes.map { |a| a.to_s }
        attr_accessor *attributes # XXX BUG: ends up on Entry, not the subclass?
      end

      def self.container(tag)
        class_variable_set(:@@response_container, tag)
      end
      # Declare fields serialized as +<apps:property name='_name1_' value='_val1_'/>...+.
      def self.properties(*properties)
        property_names.push(*properties.map { |p| p.to_s })
        attr_accessor *properties # XXX BUG: ends up on Entry, not the subclass?
      end
      
      # Declare identity fields that should not be considered updated.
      def self.identity(*identifiers)
        identity_names.push(*identifiers.map { |i| i.to_s })
      end
      
      private

      def self.get_container
        class_variable_get(:@@response_container)
      end
      
      def self.get_all_request
        class_variable_get(:@@get_all_url_proc).call(GoogleApps.dir)
      end
      
      def self.get_one_request(identifier)
        class_variable_get(:@@get_one_url_proc).call(GoogleApps.dir, identifier)
      end
      
      def self.post_new_request
        class_variable_get(:@@post_new_url_proc).call(GoogleApps.dir)
      end
      
      def self.put_updated_request(entry)
        class_variable_get(:@@put_updated_url_proc).call(GoogleApps.dir, entry)
      end
      
      def self.delete_one_request(entry)
        class_variable_get(:@@delete_one_url_proc).call(GoogleApps.dir, entry)
      end
      
      def self.attribute_tags_names
        class_variable_get(:@@attributes)
      rescue NameError
        class_variable_set(:@@attributes, {})
      end
      
      def self.property_names
        class_variable_get(:@@properties)
      rescue NameError
        class_variable_set(:@@properties, [])
      end
      
      def self.identity_names
        class_variable_get(:@@identity)
      rescue NameError
        class_variable_set(:@@identity, [])
      end
      
      def coerce(value)
        return true if value == 'true'
        return false if value == 'false'
        return value
      end

      

  end
  
end
