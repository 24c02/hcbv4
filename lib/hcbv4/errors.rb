# frozen_string_literal: true

module HCBV4
  class Error < StandardError
    attr_reader :messages

    def initialize(message = nil, messages: [])
      @messages = messages
      super(message || messages.first)
    end
  end

  class AuthenticationError < Error; end
  class TokenExpiredError < AuthenticationError; end
  class TokenRevokedError < AuthenticationError; end
  class InvalidScopeError < AuthenticationError; end

  class APIError < Error
    attr_reader :status, :error_code

    def initialize(message = nil, status: nil, error_code: nil, messages: [])
      @status = status
      @error_code = error_code
      super(message, messages:)
    end
  end

  class BadRequestError < APIError; end
  class UnauthorizedError < APIError; end
  class ForbiddenError < APIError; end
  class NotFoundError < APIError; end
  class UnprocessableEntityError < APIError; end
  class RateLimitError < APIError; end
  class ServerError < APIError; end

  class InvalidOperationError < APIError; end
  class InvalidUserError < APIError; end
end
