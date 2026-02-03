# Rack Attack Configuration
# Rate limiting and request throttling to prevent abuse

class Rack::Attack
  # Use Rails cache store for tracking request counts
  # In production, consider using Redis for better performance across multiple servers
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  ### Throttle Rules ###

  # 1. General API rate limiting
  # Limit: 300 requests per 5 minutes per IP
  # Purpose: Prevent DDoS attacks and general API abuse
  throttle("api/ip", limit: 300, period: 5.minutes) do |req|
    req.ip if req.path.start_with?("/api/")
  end

  # 2. Order creation rate limiting (strict)
  # Limit: 30 requests per minute per IP
  # Purpose: Prevent fraudulent bulk orders while allowing busy restaurants to operate
  # Rationale: 30 req/min = ~2 seconds per order, suitable for peak times
  throttle("orders/ip", limit: 30, period: 1.minute) do |req|
    if req.path == "/api/v1/customer/orders" && req.post?
      req.ip
    end
  end

  # 3. Admin API rate limiting
  # Limit: 100 requests per minute per IP
  # Purpose: Protect administrative endpoints
  throttle("admin/ip", limit: 100, period: 1.minute) do |req|
    req.ip if req.path.start_with?("/api/v1/admin/")
  end

  ### Custom Response ###

  # Customize the response when rate limit is exceeded
  self.throttled_responder = lambda do |env|
    match_data = env["rack.attack.match_data"]
    now = match_data[:epoch_time]

    # Calculate retry_after based on the period
    retry_after = match_data[:period] - (now % match_data[:period])

    [
      429, # HTTP 429 Too Many Requests
      {
        "Content-Type" => "application/json",
        "Retry-After" => retry_after.to_s
      },
      [ {
        error: "Rate limit exceeded",
        message: "リクエストが多すぎます。しばらく待ってから再度お試しください。",
        retry_after_seconds: retry_after
      }.to_json ]
    ]
  end

  ### Logging (optional) ###

  # Log blocked requests in production
  ActiveSupport::Notifications.subscribe("throttle.rack_attack") do |name, start, finish, request_id, payload|
    req = payload[:request]
    Rails.logger.warn "[Rack::Attack] Throttled: #{req.ip} #{req.request_method} #{req.fullpath}"
  end
end
