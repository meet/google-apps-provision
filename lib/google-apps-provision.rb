#require 'oauth'
#require 'rexml/document'
require 'google/api_client'
require 'active_support/core_ext'
require 'active_support/inflector'

require 'google-apps-provision/backend'
require 'google-apps-provision/connection'
require 'google-apps-provision/feed'

#require 'google-apps-provision/org'
require 'google-apps-provision/group'
require 'google-apps-provision/user'

GoogleApps.connect_with(:domain => 'meet.mit.edu',
                        :application_name => 'meet-google-sync',
                        :application_version => '0.1.0',
                        :key_file => '/home/etimmons/tmp/meet-key.p12',
                        :key_secret => 'notasecret',
                        :oauth_issuer => '858843619860-i7sttu1ahjmh9ar1jqdad0jhel40fmbj@developer.gserviceaccount.com',
                        :admin_account => 'etimmons@meet.mit.edu')
