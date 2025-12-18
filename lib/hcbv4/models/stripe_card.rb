# frozen_string_literal: true

module HCBV4
  # Physical card personalization (color, logo).
  CardPersonalization = Data.define(:color, :logo_url) do
    def self.from_hash(hash)
      return nil unless hash

      new(
        color: hash["color"],
        logo_url: hash["logo_url"]
      )
    end
  end

  # Shipping address for physical cards.
  CardShippingAddress = Data.define(:line1, :line2, :city, :state, :country, :postal_code) do
    def self.from_hash(hash)
      return nil unless hash

      new(
        line1: hash["line1"],
        line2: hash["line2"],
        city: hash["city"],
        state: hash["state"],
        country: hash["country"],
        postal_code: hash["postal_code"]
      )
    end
  end

  # Physical card shipping status and tracking.
  CardShipping = Data.define(:status, :eta, :address) do
    def self.from_hash(hash)
      return nil unless hash

      new(
        status: hash["status"],
        eta: hash["eta"],
        address: CardShippingAddress.from_hash(hash["address"])
      )
    end
  end

  # A Stripe Issuing card (virtual or physical).
  StripeCard = Data.define(
    :id, :type, :status, :name, :last4, :exp_month, :exp_year, :created_at,
    :total_spent_cents, :balance_available, :organization, :user,
    :personalization, :shipping, :_client
  ) do
    include Resource

    # @param hash [Hash] API response
    # @param client [Client, nil]
    # @return [StripeCard]
    def self.from_hash(hash, client: nil)
      new(
        id: hash["id"],
        type: hash["type"],
        status: hash["status"],
        name: hash["name"],
        last4: hash["last4"],
        exp_month: hash["exp_month"],
        exp_year: hash["exp_year"],
        created_at: hash["created_at"],
        total_spent_cents: hash["total_spent_cents"],
        balance_available: hash["balance_available"],
        organization: hash["organization"] ? Organization.from_hash(hash["organization"]) : nil,
        user: hash["user"] ? User.from_hash(hash["user"]) : nil,
        personalization: CardPersonalization.from_hash(hash["personalization"]),
        shipping: CardShipping.from_hash(hash["shipping"]),
        _client: client
      )
    end

    # Freezes the card, blocking new transactions.
    # @return [StripeCard]
    def freeze!
      require_client!
      _client.update_stripe_card(id, status: "frozen")
    end

    # Unfreezes a frozen card.
    # @return [StripeCard]
    def defrost!
      require_client!
      _client.update_stripe_card(id, status: "active")
    end

    # Permanently cancels the card.
    # @return [Hash]
    def cancel!
      require_client!
      _client.cancel_stripe_card(id)
    end

    # Refreshes card data from the API.
    # @return [StripeCard]
    def reload!
      require_client!
      _client.stripe_card(id)
    end

    # Activates a physical card after receiving it.
    # @param last4 [String] last 4 digits printed on the card
    # @return [StripeCard]
    def activate!(last4:)
      require_client!
      _client.update_stripe_card(id, status: "active", last4:)
    end

    # Returns paginated transactions for this card.
    # @return [TransactionList]
    def transactions(**opts)
      require_client!
      _client.stripe_card_transactions(id, **opts)
    end

    # Returns Stripe ephemeral keys for revealing sensitive card details.
    # @param nonce [String] one-time nonce
    # @param stripe_version [String, nil]
    # @return [Hash]
    def ephemeral_keys(nonce:, stripe_version: nil)
      require_client!
      _client.stripe_card_ephemeral_keys(id, nonce:, stripe_version:)
    end

    # @return [Boolean]
    def virtual? = type == "virtual"

    # @return [Boolean]
    def physical? = type == "physical"
  end
end
