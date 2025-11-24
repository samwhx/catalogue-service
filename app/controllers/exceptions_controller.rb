class ExceptionsController < ActionController::API
  def not_found
    render json: { error: "Route not found", status: 404 }, status: :not_found
  end
end
