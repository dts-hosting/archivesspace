require 'aspace-rails/asset_path_rewriter'
require 'aspace-rails/compressor'

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Disable serving static files from the `/public` folder by default since
  # Apache or NGINX already handles this.
  config.public_file_server.enabled = true

  # Compress JavaScripts and CSS.
  config.assets.js_compressor = ASpaceCompressor.new(:js)
  config.assets.css_compressor = ASpaceCompressor.new(:css)

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = true

  # Generate digests for assets URLs
  config.assets.digest = true

  # `config.assets.precompile` and `config.assets.version` have moved to config/initializers/assets.rb

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.action_controller.asset_host = 'http://assets.example.com'

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = 'X-Sendfile' # for Apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for NGINX

  # Mount Action Cable outside main process or domain
  # config.action_cable.mount_path = nil
  # config.action_cable.url = 'wss://example.com/cable'
  # config.action_cable.allowed_request_origins = [ 'http://example.com', /http:\/\/example.*/ ]

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = AppConfig[:force_ssl]

  # Use the lowest log level to ensure availability of diagnostic information
  # when problems arise.
  # config.log_level = :debug

  # Prepend all log lines with the following tags.
  config.log_tags = [ :request_id ]

  # Use a different cache store in production.
  # config.cache_store = :mem_cache_store

  # Use a real queuing backend for Active Job (and separate queues per environment)
  # config.active_job.queue_adapter     = :resque
  # config.active_job.queue_name_prefix = "archivesspace-public_#{Rails.env}"
  # DISABLED BY MST # config.action_mailer.perform_caching = false

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # DISABLED BY MST # # config.action_mailer.raise_delivery_errors = false

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  # Use default logging formatter so that PID and timestamp are not suppressed.
  # config.log_formatter = ::Logger::Formatter.new

  # Use a different logger for distributed setups.
  # require 'syslog/logger'
  # config.logger = ActiveSupport::TaggedLogging.new(Syslog::Logger.new 'app-name')

  # if ENV["RAILS_LOG_TO_STDOUT"].present?
  # logger           = ActiveSupport::Logger.new(STDOUT)
  #  logger.formatter = config.log_formatter
  #   config.logger = ActiveSupport::TaggedLogging.new(logger)
  #end

  # Do not dump schema after migrations.
  # DISABLED BY MST # config.active_record.dump_schema_after_migration = false

  # The default file handler doesn't know about asset prefixes and returns a 404.  Make it strip the prefix before looking for the path on disk.
  if AppConfig[:public_proxy_prefix] && AppConfig[:public_proxy_prefix].length > 1
    require 'action_dispatch/middleware/static'
    module ActionDispatch
      class FileHandler
        private

        def find_file(path_info, accept_encoding:)
          prefix = AppConfig[:public_proxy_prefix]
          each_candidate_filepath(path_info) do |filepath, content_type|
            filepath = filepath.gsub(/^#{Regexp.quote(prefix)}/, "/")
            if response = try_files(filepath, content_type, accept_encoding: accept_encoding)
              return response
            end
          end
        end
      end
    end

    AssetPathRewriter.new.rewrite(AppConfig[:public_proxy_prefix], File.dirname(__FILE__))
  end

  # Infinite Tree and Records config
  config.infinite_tree_batch_size = 200
  config.infinite_records_waypoint_size = 20
  config.infinite_records_main_max_concurrent_waypoint_fetches = 20
  config.infinite_records_worker_max_concurrent_waypoint_fetches = 100
end
