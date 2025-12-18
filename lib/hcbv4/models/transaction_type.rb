# frozen_string_literal: true

module HCBV4
  module TransactionType
    COMMON_FIELDS = %i[id amount_cents memo status].freeze

    def transaction? = true
    def pending? = respond_to?(:pending) && pending
    def declined? = respond_to?(:declined) && declined
  end
end
