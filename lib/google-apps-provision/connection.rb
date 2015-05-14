# Represents the Google Apps service.
module GoogleApps
  
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
    @@connection ||= @@backend.new(@@connection_params)
  end
  
  # A Google Apps API error.
  class GoogleError < RuntimeError
    
    def initialize(result)
      @status = result.status
      @reason = result.error_message
    end
    
    def to_s
      "#{@status} #{@reason}"
    end
    
  end
  
end
