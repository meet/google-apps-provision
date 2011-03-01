# Represents the Google Apps service.
module GoogleApps
  
  ENDPOINT = 'https://apps-apis.google.com/a/feeds'
  
  @@backend = Read
  @@connection = nil
  @@connection_params = { }
  
  # Get the backend used for new connections.
  def self.backend
    @@backend
  end
  
  # Set the backend.
  def self.backend=(backend)
    @@backend = backend
    @@connection = nil
  end
  
  # Add connection parameters. Discards any current connection.
  def self.connect_with(connection_params)
    @@connection = nil
    @@connection_params.merge!(connection_params)
  end
  
  # Obtain the current connection, creating one if necessary.
  def self.connection
    @@connection ||= @@backend.new(@@connection_params).extend Feeds
  end
  
  module Feeds
    
    def customer_id
      url = "#{ENDPOINT}/customer/2.0/customerId"
      @customer_id ||= REXML::Document.new(get(url).body).get_elements('entry/apps:property').find do |prop|
        prop.attributes['name'] == 'customerId'
      end .attributes['value']
    end
    
    def get_feed(url)
      return REXML::Document.new(get(url).body)
    end
    
    def get_feed_all(url)
      xml = get_feed(url)
      return xml, xml.get_elements('feed/link').find { |link| link.attributes['rel'] == 'next' }
    end
    
    def post_feed(url, xml)
      return post(url, xml.to_s, { 'Content-Type' => 'application/atom+xml' })
    end
    
    def put_feed(url, xml)
      return put(url, xml.to_s, { 'Content-Type' => 'application/atom+xml' })
    end
    
    def delete_feed(url)
      return delete(url)
    end
    
  end
  
  # A Google Apps API error.
  class GoogleError < RuntimeError
    
    def initialize(result)
      @status = result.code
      doc = REXML::Document.new(result.body)
      if elt = doc.elements['AppsForYourDomainErrors/error']
        @reason, @input = elt.attributes['reason'], elt.attributes['invalidInput']
      elsif elt = doc.elements['//H1']
        @reason = elt.text
      end
    end
    
    def to_s
      "#{@status} #{@reason} #{@input}"
    end
    
  end
  
end
