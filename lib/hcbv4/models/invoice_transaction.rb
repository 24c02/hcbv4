# frozen_string_literal: true

module HCBV4
  # Sponsor info embedded in invoice transactions.
  InvoiceSponsor = Data.define(:id, :name, :email) do
    def self.from_hash(hash)
      return nil unless hash

      new(
        id: hash["id"],
        name: hash["name"],
        email: hash["email"]
      )
    end
  end

  # Invoice payment details on a transaction.
  class InvoiceTransaction < BaseTransactionDetail
    attr_reader :sent_at, :paid_at, :description, :due_date, :sponsor

    def initialize(id: nil, amount_cents: nil, memo: nil, status: nil, sent_at: nil, paid_at: nil,
                   description: nil, due_date: nil, sponsor: nil)
      super(id:, amount_cents:, memo:, status:)
      @sent_at = sent_at
      @paid_at = paid_at
      @description = description
      @due_date = due_date
      @sponsor = sponsor
    end

    # @param hash [Hash] API response
    # @return [InvoiceTransaction]
    def self.from_hash(hash)
      new(
        id: hash["id"],
        amount_cents: hash["amount_cents"],
        memo: hash["memo"],
        status: hash["status"],
        sent_at: hash["sent_at"],
        paid_at: hash["paid_at"],
        description: hash["description"],
        due_date: hash["due_date"],
        sponsor: InvoiceSponsor.from_hash(hash["sponsor"])
      )
    end
  end
end
