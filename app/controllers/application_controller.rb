class ApplicationController < ActionController::API
  rescue_from StandardError, with: :handle_error
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  private

  def render_with_cache(cache_key, expires_in: 1.hour)
    cached = Rails.cache.read(cache_key)
    return render json: cached, status: :ok if cached

    begin
      response_data = yield
      Rails.cache.write(cache_key, response_data, expires_in: expires_in)
      render json: response_data, status: :ok
    rescue StandardError
      # Don't cache errors - re-raise to be handled by rescue_from
      raise
    end
  end

  def handle_error(error)
    # TODO: Add error logging to Sentry/Airbrake
    Rails.logger.error("Error in #{self.class.name}: #{error.message}")
    Rails.logger.error(error.backtrace.join("\n"))
    render json: { error: "Internal server error", status: 500 }, status: :internal_server_error
  end

  def render_not_found
    # TODO: Add error logging to Sentry/Airbrake
    render json: { error: "Resource not found", status: 404 }, status: :not_found
  end
end
