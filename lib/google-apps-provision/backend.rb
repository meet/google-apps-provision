module GoogleApps
  @@dir = nil
  @@discovered_directory_api_file = nil

  def self.load_dir_from_file
    doc = File.read(discovered_directory_api_file)
    client = Google::APIClient.new(
      :application_name => "dump_file",
      :application_version => "0.1.0")
    client.register_discovery_document('admin', 'directory_v1', doc)
    client.discovered_api('admin', 'directory_v1')
  end
  
  def self.dir
    @@dir ||= load_dir_from_file
    @@dir
  end

  def self.dump_directory_to_file
    client = Google::APIClient.new(
      :application_name => "dump_file",
      :application_version => "0.1.0")
    File.open(discovered_directory_api_file, "w") do |f|
      f.syswrite(client.discovery_document("admin", "directory_v1").to_json)
    end
  end

  def self.discovered_directory_api_file
    @@discovered_directory_api_file
  end

  def self.discovered_directory_api_file=(value)
    @@discovered_directory_api_file = value
  end
  # Mock backend.
  # class Mock
    
  #   # Mock response.
  #   class Response < Struct.new(:code, :body)
  #   end
    
  #   attr_reader :domain
    
  #   def initialize(params)
  #     @domain = params[:domain]
  #     @mocks = {}
  #     @changes = []
  #   end
    
  #   # Mock a raw XML response.
  #   # First argument indicates HTTP method, e.g. +:GET+.
  #   # Subsequent arguments are arguments to the corresponding method of +OAuth::AccessToken+.
  #   # Last argument is the content to return.
  #   def mock_xml(*args)
  #     @mocks[args[0..-2]] = args[-1]
  #   end
    
  #   # Mock a serialized entry response.
  #   def mock_entry(identifier, entry)
  #     url = entry.class.get_one_url(identifier)
  #     xml = Feed.new(entry.class).add_entry(entry).to_xml
  #     xml.elements['*:entry'].add_element('atom:id').add_text(url)
  #     mock_xml(:GET, url, xml.to_s)
  #   end
    
  #   # Mock an organizational customer.
  #   def mock_customer(identifier)
  #     xml = Feed.new(nil).to_xml
  #     elt = xml.add_element('entry', { 'xmlns:apps' => 'http://schemas.google.com/apps/2006' })
  #     elt.add_element('apps:property', { 'name' => 'customerId', 'value' => identifier })
  #     mock_xml(:GET, "#{ENDPOINT}/customer/2.0/customerId", xml.to_s)
  #   end
    
  #   def clear_mocks
  #     @mocks.clear
  #   end
    
  #   def changes
  #     @changes
  #   end
    
  #   def clear_changes
  #     @changes.clear
  #   end
    
  #   def get(*args)
  #     body = @mocks[[ :GET ] + args]
  #     return Response.new('200', body) if body
  #     raise GoogleError.new(Response.new('404', ''))
  #   end
    
  #   def post(*args)
  #     @changes << [ :POST ] + args
  #   end
    
  #   def put(*args)
  #     @changes << [ :PUT ] + args
  #   end
    
  #   def delete(*args)
  #     @changes << [ :DELETE ] + args
  #   end
    
  # end
  
  # Backend that implements reading.
  class Read
    
    attr_reader :domain
    attr_reader :changes
    attr_reader :dir
    attr_reader :api_client
    
    def initialize(params)
      @domain = params[:domain]
      @api_client = Google::APIClient.new(
        :application_name => params[:application_name],
        :application_version => params[:application_version])
      key = Google::APIClient::KeyUtils.load_from_pkcs12(params[:key_file], params[:key_secret])
      @api_client.authorization = Signet::OAuth2::Client.new(
        :token_credential_uri => 'https://accounts.google.com/o/oauth2/token',
        :audience => 'https://accounts.google.com/o/oauth2/token',
        :scope => ['https://www.googleapis.com/auth/admin.directory.group.readonly',
                   'https://www.googleapis.com/auth/admin.directory.orgunit.readonly',
                   'https://www.googleapis.com/auth/admin.directory.user.readonly'],
        :issuer => params[:oauth_issuer],
        :signing_key => key,
        :sub => params[:admin_account])
      @api_client.authorization.fetch_access_token!
      @api_client.retries = 2
      @changes = []
    end

    def execute(request)
      # The read backend executes only HTTP gets.
      if request.respond_to? :api_method
        http_method = request.api_method.http_method
      else
        http_method = request[:api_method].http_method
      end
      if http_method == 'GET'
        result = @api_client.execute(request)
        return result unless result.error?
        raise GoogleError.new(result)
      else
        @changes << request
      end
    end
    
  end
  
  # Backend that implements reading and writing.
  class ReadWrite < Read

    def initialize(params)
      @domain = params[:domain]
      @api_client = Google::APIClient.new(
        :application_name => params[:application_name],
        :application_version => params[:application_version])
      key = Google::APIClient::KeyUtils.load_from_pkcs12(params[:key_file], params[:key_secret])
      @api_client.authorization = Signet::OAuth2::Client.new(
        :token_credential_uri => 'https://accounts.google.com/o/oauth2/token',
        :audience => 'https://accounts.google.com/o/oauth2/token',
        :scope => ['https://www.googleapis.com/auth/admin.directory.group',
                   'https://www.googleapis.com/auth/admin.directory.orgunit',
                   'https://www.googleapis.com/auth/admin.directory.user'],
        :issuer => params[:oauth_issuer],
        :signing_key => key,
        :sub => params[:admin_account])
      @api_client.authorization.fetch_access_token!
      @dir = @api_client.discovered_api('admin', 'directory_v1')
    end

    def execute(request)
      result = @api_client.execute(request)
      return result unless result.error?
      raise GoogleError.new(result)
    end
    
  end
  
end
