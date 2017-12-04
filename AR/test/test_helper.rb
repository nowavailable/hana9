require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'timecop'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  # fixtures :all

  # Add more helper methods to be used by all tests here...
  def create_context_fixtures(context_name, *fixture_set_names, &block)
    ActiveRecord::FixtureSet.create_fixtures(
      File.join(ActiveSupport::TestCase.fixture_path, context_name),
      fixture_set_names, {}, &block
    )
  end
end
