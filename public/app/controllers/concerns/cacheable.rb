module Cacheable
  extend ActiveSupport::Concern

  included do
    before_action :set_cache_headers
  end

  private

  def set_cache_headers
    response.headers["Cache-Control"] = AppConfig[:pui_cache_control]
  end
end
