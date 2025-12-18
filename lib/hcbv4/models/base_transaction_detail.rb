# frozen_string_literal: true

module HCBV4
  # Base class for transaction detail types (Transfer, AchTransfer, Check, etc.).
  class BaseTransactionDetail
    include TransactionType

    attr_reader :id, :amount_cents, :memo, :status

    def initialize(id:, amount_cents: nil, memo: nil, status: nil)
      @id = id
      @amount_cents = amount_cents
      @memo = memo
      @status = status
    end

    # @param hash [Hash] API response
    # @return [BaseTransactionDetail]
    def self.from_hash(hash)
      new(
        id: hash["id"],
        amount_cents: hash["amount_cents"],
        memo: hash["memo"],
        status: hash["status"]
      )
    end

    def ==(other)
      other.is_a?(self.class) && id == other.id
    end
    alias eql? ==

    def hash
      id.hash
    end
  end
end
