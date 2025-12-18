# frozen_string_literal: true

module HCBV4
  # Expense reimbursement payout details.
  class ExpensePayout < BaseTransactionDetail
    attr_reader :report_id

    def initialize(id: nil, amount_cents: nil, memo: nil, status: nil, report_id: nil)
      super(id:, amount_cents:, memo:, status:)
      @report_id = report_id
    end

    # @param hash [Hash] API response
    # @return [ExpensePayout]
    def self.from_hash(hash)
      new(
        id: hash["id"],
        amount_cents: hash["amount_cents"],
        memo: hash["memo"],
        status: hash["status"],
        report_id: hash["report_id"]
      )
    end
  end
end
