module GoogleApps
  
  # Mock backend.
  class Mock
    
    # Mock response.
    class Response < Struct.new(:body)
    end
    
    attr_reader :domain
    
    def initialize(params)
      @domain = params[:domain]
      @mocks = {}
    end
    
    # Mock a response.
    # First argument indicates HTTP method, e.g. +:GET+.
    # Subsequent arguments are arguments to the corresponding method of +OAuth::AccessToken+.
    # Last argument is the content to return.
    def mock(*args)
      @mocks[args[0..-2]] = args[-1]
    end
    
    def get(*args)
      Response.new(@mocks.delete([ :GET ] + args))
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
      super
      result = @token.post(*args)
      return result if result.is_a? Net::HTTPCreated
      raise GoogleError.new(result)
    end
    
    def put(*args)
      super
      result = @token.put(*args)
      return result if result.is_a? Net::HTTPSuccess
      raise GoogleError.new(result)
    end
    
    def delete(*args)
      super
      result = @token.delete(*args)
      return result if result.is_a? Net::HTTPSuccess
      raise GoogleError.new(result)
    end
    
  end
  
end
