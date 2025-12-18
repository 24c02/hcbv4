# frozen_string_literal: true

module HCBV4
  # Card purchase details for a transaction.
  # @attr_reader merchant [Merchant, nil] merchant info
  # @attr_reader charge_method [String, nil] "chip", "swipe", "contactless", etc.
  # @attr_reader spent_at [String, nil] ISO timestamp
  # @attr_reader wallet [String, nil] "apple_pay", "google_pay", etc.
  # @attr_reader card [StripeCard, nil] the card used
  CardCharge = Data.define(:merchant, :charge_method, :spent_at, :wallet, :card) do
    include TransactionType

    # @param hash [Hash] API response
    # @return [CardCharge]
    def self.from_hash(hash)
      new(
        merchant: hash["merchant"] ? Merchant.from_hash(hash["merchant"]) : nil,
        charge_method: hash["charge_method"],
        spent_at: hash["spent_at"],
        wallet: hash["wallet"],
        card: hash["card"] ? StripeCard.from_hash(hash["card"]) : nil
      )
    end
  end
end
