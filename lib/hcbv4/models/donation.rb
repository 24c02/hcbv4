# frozen_string_literal: true

module HCBV4
  # A created donation record. Only contains the id.
  # Full donation details are available via DonationTransaction on transactions.
  Donation = Data.define(:id) do
    # @param hash [Hash] API response
    # @return [Donation]
    def self.from_hash(hash) = new(id: hash["id"])
  end
end
