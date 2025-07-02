module Cacheable
  extend ActiveSupport::Concern

  included do
    before_action :set_cache_headers
  end

  private

  def set_cache_headers
    # Cache for 1 hour, public
    response.headers['Cache-Control'] = 'public, max-age=3600'
  end
end
