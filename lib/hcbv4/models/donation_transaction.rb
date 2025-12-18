# frozen_string_literal: true

module HCBV4
  # Donor info for a donation.
  DonationDonor = Data.define(:name, :email, :recurring_donor_id) do
    def self.from_hash(hash)
      return nil unless hash

      new(
        name: hash["name"],
        email: hash["email"],
        recurring_donor_id: hash["recurring_donor_id"]
      )
    end
  end

  # UTM attribution info for tracking donation sources.
  DonationAttribution = Data.define(:referrer, :utm_source, :utm_medium, :utm_campaign, :utm_term, :utm_content) do
    def self.from_hash(hash)
      return nil unless hash

      new(
        referrer: hash["referrer"],
        utm_source: hash["utm_source"],
        utm_medium: hash["utm_medium"],
        utm_campaign: hash["utm_campaign"],
        utm_term: hash["utm_term"],
        utm_content: hash["utm_content"]
      )
    end
  end

  # Donation details on a transaction.
  # @attr_reader recurring [Boolean, nil] true if recurring donation
  # @attr_reader donor [DonationDonor, nil] donor info
  # @attr_reader attribution [DonationAttribution, nil] UTM tracking
  # @attr_reader message [String, nil] donor message
  # @attr_reader donated_at [String, nil] ISO timestamp
  # @attr_reader refunded [Boolean, nil]
  class DonationTransaction < BaseTransactionDetail
    attr_reader :recurring, :donor, :attribution, :message, :donated_at, :refunded

    def initialize(id: nil, amount_cents: nil, memo: nil, status: nil, recurring: nil, donor: nil,
                   attribution: nil, message: nil, donated_at: nil, refunded: nil)
      super(id:, amount_cents:, memo:, status:)
      @recurring = recurring
      @donor = donor
      @attribution = attribution
      @message = message
      @donated_at = donated_at
      @refunded = refunded
    end

    # @param hash [Hash] API response
    # @return [DonationTransaction]
    def self.from_hash(hash)
      new(
        id: hash["id"],
        amount_cents: hash["amount_cents"],
        memo: hash["memo"],
        status: hash["status"],
        recurring: hash["recurring"],
        donor: DonationDonor.from_hash(hash["donor"]),
        attribution: DonationAttribution.from_hash(hash["attribution"]),
        message: hash["message"],
        donated_at: hash["donated_at"],
        refunded: hash["refunded"]
      )
    end

    # @return [Boolean]
    def recurring? = !!recurring

    # @return [Boolean]
    def refunded? = !!refunded
  end
end
