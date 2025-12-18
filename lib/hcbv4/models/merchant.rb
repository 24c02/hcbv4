# frozen_string_literal: true

module HCBV4
  # Merchant info for card transactions.
  # @attr_reader name [String, nil] raw merchant name from Stripe
  # @attr_reader smart_name [String, nil] cleaned up merchant name
  # @attr_reader country [String, nil] two-letter country code
  # @attr_reader network_id [String, nil] merchant category code
  Merchant = Data.define(:name, :smart_name, :country, :network_id) do
    # @param hash [Hash] API response
    # @return [Merchant]
    def self.from_hash(hash)
      new(name: hash["name"], smart_name: hash["smart_name"], country: hash["country"], network_id: hash["network_id"])
    end
  end
end
