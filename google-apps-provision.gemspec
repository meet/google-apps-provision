$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "google-apps-provision"
  s.version     = "0.0.2"
  s.authors     = ["Max Goldman", "Eric Timmons"]
  s.email       = ["etimmons@mit.edu"]
  s.homepage    = ""
  s.summary     = %q{Provision google users and groups.}
  s.description = %q{Provision google users and groups.}

  s.require_paths = ["lib"]

  s.add_runtime_dependency "activesupport"
  s.add_runtime_dependency "i18n"
  s.add_runtime_dependency "google-api-client"
end
