# frozen_string_literal: true

require_relative "hcbv4/version"
require_relative "hcbv4/errors"
require_relative "hcbv4/models"
require_relative "hcbv4/client"

module HCBV4
  class Error < StandardError; end
end
