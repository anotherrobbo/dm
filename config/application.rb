require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Dm
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set root context for URLs
    config.relative_url_root = ENV['RAILS_CONTEXT'] || '/'
    
    # Use a file store cache with compression
    config.cache_store = :file_store, ENV['RAILS_CACHE_DIR'] || 'tmp/cache', {compress: true}
    
    # Logging
    config.logger = Logger.new(STDOUT)
    config.logger.level = Logger.const_get(ENV['LOG_LEVEL'] ? ENV['LOG_LEVEL'].upcase : 'INFO')
    config.log_level    = (ENV['LOG_LEVEL'] ? ENV['LOG_LEVEL'].downcase : 'info').to_sym
    
  end
end
