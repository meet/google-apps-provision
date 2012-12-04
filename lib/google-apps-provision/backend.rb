module GoogleApps
  
  # Mock backend.
  class Mock
    
    # Mock response.
    class Response < Struct.new(:code, :body)
    end
    
    attr_reader :domain
    
    def initialize(params)
      @domain = params[:domain]
      @mocks = {}
      @changes = []
    end
    
    # Mock a raw XML response.
    # First argument indicates HTTP method, e.g. +:GET+.
    # Subsequent arguments are arguments to the corresponding method of +OAuth::AccessToken+.
    # Last argument is the content to return.
    def mock_xml(*args)
      @mocks[args[0..-2]] = args[-1]
    end
    
    # Mock a serialized entry response.
    def mock_entry(identifier, entry)
      url = entry.class.get_one_url(identifier)
      xml = Feed.new(entry.class).add_entry(entry).to_xml
      xml.elements['*:entry'].add_element('atom:id').add_text(url)
      mock_xml(:GET, url, xml.to_s)
    end
    
    # Mock an organizational customer.
    def mock_customer(identifier)
      xml = Feed.new(nil).to_xml
      elt = xml.add_element('entry', { 'xmlns:apps' => 'http://schemas.google.com/apps/2006' })
      elt.add_element('apps:property', { 'name' => 'customerId', 'value' => identifier })
      mock_xml(:GET, "#{ENDPOINT}/customer/2.0/customerId", xml.to_s)
    end
    
    def clear_mocks
      @mocks.clear
    end
    
    def changes
      @changes
    end
    
    def clear_changes
      @changes.clear
    end
    
    def get(*args)
      body = @mocks[[ :GET ] + args]
      return Response.new('200', body) if body
      raise GoogleError.new(Response.new('404', ''))
    end
    
    def post(*args)
      @changes << [ :POST ] + args
    end
    
    def put(*args)
      @changes << [ :PUT ] + args
    end
    
    def delete(*args)
      @changes << [ :DELETE ] + args
    end
    
  end
  
  # Backend that implements reading.
  class Read
    
    attr_reader :domain
    attr_reader :changes
    
    def initialize(params)
      @domain = params[:domain]
      consumer = OAuth::Consumer.new(@domain,
                                     params[:consumer_secret],
                                     :site => 'https://www.google.com',
                                     :request_token_path => '/accounts/OAuthGetRequestToken',
                                     :access_token_path => '/accounts/OAuthGetAccessToken',
                                     :authorize_path=> '/accounts/OAuthAuthorizeToken')
      @token = OAuth::AccessToken.new(consumer,
                                      params[:access_token],
                                      params[:access_secret])
      @changes = []
    end
    
    def get(*args)
      result = @token.get(*args)
      return result if result.is_a? Net::HTTPSuccess
      raise GoogleError.new(result)
    end
    
    def post(*args)
      @changes << [ :POST ] + args
    end
    
    def put(*args)
      @changes << [ :PUT ] + args
    end
    
    def delete(*args)
      @changes << [ :DELETE ] + args
    end
    
  end
  
  # Backend that implements reading and writing.
  class ReadWrite < Read
    
    def post(*args)
      result = @token.post(*args)
      return result if result.is_a? Net::HTTPCreated
      raise GoogleError.new(result)
    end
    
    def put(*args)
      result = @token.put(*args)
      return result if result.is_a? Net::HTTPSuccess
      raise GoogleError.new(result)
    end
    
    def delete(*args)
      result = @token.delete(*args)
      return result if result.is_a? Net::HTTPSuccess
      raise GoogleError.new(result)
    end
    
  end
  
end
