# frozen_string_literal: true

module HCBV4
  # An invoice sent to a sponsor.
  Invoice = Data.define(
    :id, :status, :created_at, :to, :amount_due, :memo, :due_date,
    :item_amount, :item_description, :sponsor_id, :_client
  ) do
    include Resource

    # @param hash [Hash] API response
    # @param client [Client, nil]
    # @return [Invoice]
    def self.from_hash(hash, client: nil)
      new(
        id: hash["id"], status: hash["status"], created_at: hash["created_at"], to: hash["to"],
        amount_due: hash["amount_due"], memo: hash["memo"], due_date: hash["due_date"],
        item_amount: hash["item_amount"], item_description: hash["item_description"], sponsor_id: hash["sponsor_id"],
        _client: client
      )
    end

    # Refreshes invoice data from the API.
    # @return [Invoice]
    def reload! = (require_client!; _client.invoice(id))
  end
end
