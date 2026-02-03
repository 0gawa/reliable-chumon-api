module ErrorHandler
  extend ActiveSupport::Concern

  included do
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
    rescue_from ActiveRecord::RecordInvalid, with: :render_validation_error
    rescue_from ActiveRecord::StaleObjectError, with: :render_stale_object
    rescue_from ActionController::ParameterMissing, with: :render_missing_parameter
  end

  private

  def render_error(status:, code:, message:, details: {})
    render json: {
      error: {
        status: Rack::Utils.status_code(status),
        code: code,
        message: message,
        details: details,
        timestamp: Time.current.iso8601
      }
    }, status: status
  end

  def render_not_found(exception = nil)
    render_error(
      status: :not_found,
      code: ErrorCode::NOT_FOUND,
      message: "Resource not found",
      details: { resource: exception&.model }
    )
  end

  def render_validation_error(exception)
    render_error(
      status: :unprocessable_entity,
      code: ErrorCode::VALIDATION_ERROR,
      message: "Validation failed",
      details: { errors: exception.record&.errors&.full_messages || [] }
    )
  end

  def render_stale_object(exception = nil)
    render_error(
      status: :conflict,
      code: ErrorCode::STALE_OBJECT,
      message: "Resource was modified by another request",
      details: {}
    )
  end

  def render_missing_parameter(exception)
    render_error(
      status: :bad_request,
      code: ErrorCode::MISSING_PARAMETER,
      message: "Required parameter is missing",
      details: { parameter: exception.param }
    )
  end

  def render_duplicate_request
    render_error(
      status: :ok,
      code: ErrorCode::DUPLICATE_REQUEST,
      message: "Duplicate request detected, returning existing resource",
      details: {}
    )
  end

  def render_deadlock
    render_error(
      status: :conflict,
      code: ErrorCode::DEADLOCK,
      message: "Transaction deadlock detected",
      details: { suggestion: "Please retry your request" }
    )
  end

  def render_custom_error(status:, code:, message:, details: {})
    render_error(
      status: status,
      code: code,
      message: message,
      details: details
    )
  end
end
