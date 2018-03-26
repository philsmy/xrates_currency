Gem::Specification.new do |s|
  s.name        = "xrates_currency"
  s.version     = "3.4.0"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Phil Smy"]
  s.email       = ["phil@philsmy.com"]
  s.homepage    = "http://philsmy.github.com/xrates_currency"
  s.summary     = "Access the XRates Currency exchange rate data."
  s.description = "XratesCurrency extends Money::Bank::Base and gives you access to the current XRate Currency exchange rates."
  s.license     = 'MIT'

  s.add_development_dependency "rspec", ">= 3.0.0"
  s.add_development_dependency "yard", ">= 0.5.8"
  s.add_development_dependency "ffi"

  s.add_dependency "money", "~> 6.7"

  s.files =  Dir.glob("{lib,spec}/**/*")
  s.files += %w(LICENSE README.md CHANGELOG.md AUTHORS)
  s.files += %w(Rakefile .gemtest xrate_currency.gemspec)

  s.require_path = "lib"
end
