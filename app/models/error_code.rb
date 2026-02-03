class ErrorCode
  # Validation errors
  VALIDATION_ERROR = "VALIDATION_ERROR"
  MISSING_PARAMETER = "MISSING_PARAMETER"

  # Resource errors
  NOT_FOUND = "NOT_FOUND"
  ALREADY_EXISTS = "ALREADY_EXISTS"

  # Concurrency control errors
  DUPLICATE_REQUEST = "DUPLICATE_REQUEST"
  STALE_OBJECT = "STALE_OBJECT"
  DEADLOCK = "DEADLOCK"

  # System errors
  INTERNAL_ERROR = "INTERNAL_ERROR"

  def self.all
    constants.map { |c| const_get(c) }
  end
end
