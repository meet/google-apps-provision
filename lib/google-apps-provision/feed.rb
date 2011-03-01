module GoogleApps
  
  # Base class for feed entries.
  class Entry
    
    # Find all entries of this type.
    def self.all
      xml, more = GoogleApps.connection.get_feed_all(get_all_url)
      feed = Feed.new(self).add_xml(xml)
      while more
        xml, more = GoogleApps.connection.get_feed_all(more.attributes['href'])
        feed.add_xml(xml)
      end
      return feed
    end
    
    # Find the entry with this identifier.
    def self.find(identifier)
      xml = GoogleApps.connection.get_feed(get_one_url(identifier))
      return self.new.load(xml.elements['*:entry'])
    end
    
    attr_reader :url
    
    def initialize(attributes={})
      @url = nil
      @loaded = {}
      @deleted = false
      attributes.each do |attrib, value|
        send("#{attrib}=", value)
      end
    end
    
    # Load in fields from XML.
    def load(entry)
      @url = entry.elements['*:id'].text
      
      entry.elements.each('apps:*') do |elt|
        if elt.name == 'property'
          value = coerce(elt.attributes['value'])
          @loaded[elt.attributes['name'].underscore] = value
          send("#{elt.attributes['name'].underscore}=", value)
        else
          elt.attributes.each do |name, value|
            value = coerce(value)
            @loaded[name.underscore] = value
            send("#{name.underscore}=", value)
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
      return true if url == nil
      return ! changed.empty?
    end
    
    # Save this entry, either by creating, deleting, or updating.
    def save
      if deleted?
        GoogleApps.connection.delete_feed(self.class.delete_one_url(self))
      elsif url == nil
        GoogleApps.connection.post_feed(self.class.post_new_url,
                                        Feed.new(self.class).add_entry(self).to_xml)
      elsif ! changed.empty?
        GoogleApps.connection.put_feed(self.class.put_updated_url(self),
                                       Feed.new(self.class).add_entry_changes(self).to_xml)
      end
    end
    
    # Yields each element in the XML representation of this entry.
    def each_xml
      self.class.attribute_tags_names.each do |tag, names|
        set = names.each_with_object({}) { |name, set| set[name.camelcase(:lower)] = send(name) }
        set.delete_if { |name, value| value == nil }
        if not set.empty?
          elt = REXML::Element.new(tag)
          elt.add_attributes(set)
          yield elt
        end
      end
      self.class.property_names.each do |name|
        if (value = send(name)) != nil
          elt = REXML::Element.new('apps:property')
          elt.add_attributes('name' => name.camelcase(:lower), 'value' => value)
          yield elt
        end
      end
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
      
      def self.get_all_url
        class_variable_get(:@@get_all_url_proc).call
      end
      
      def self.get_one_url(identifier)
        class_variable_get(:@@get_one_url_proc).call(identifier)
      end
      
      def self.post_new_url
        class_variable_get(:@@post_new_url_proc).call
      end
      
      def self.put_updated_url(entry)
        class_variable_get(:@@put_updated_url_proc).call(entry)
      end
      
      def self.delete_one_url(entry)
        class_variable_get(:@@delete_one_url_proc).call(entry)
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
  
  # A Google Data API feed.
  class Feed
    
    include Enumerable
    
    def initialize(elt_class)
      @entries = []
      @elt_class = elt_class
    end
    
    def add_xml(xml)
      xml.elements.each('feed/entry') { |entry| @entries << @elt_class.new.load(entry) }
      return self
    end
    
    def add_entry(entry)
      @entries << entry
      return self
    end
    
    def add_entry_changes(entry)
      diff = @elt_class.new
      entry.changed.each do |name|
        diff.send("#{name}=", entry.send(name))
      end
      return add_entry(diff)
    end
    
    def to_xml
      xml = REXML::Document.new('<?xml version="1.0" encoding="UTF-8"?>')
      @entries.each do |entry|
        elt = xml.add_element('atom:entry', { 'xmlns:atom' => 'http://www.w3.org/2005/Atom',
                                              'xmlns:apps' => 'http://schemas.google.com/apps/2006',
                                              'xmlns:gd' => 'http://schemas.google.com/g/2005' })
        entry.each_xml { |tag| elt.add_element(tag) }
      end
      return xml
    end
    
    # Implement Enumerable
    
    def each(&block)
      @entries.each(&block)
    end
    
  end
  
end
