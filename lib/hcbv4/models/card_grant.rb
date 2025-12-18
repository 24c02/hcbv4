# frozen_string_literal: true

module HCBV4
  # A virtual card grant with optional spending restrictions.
  # Can be topped up, withdrawn, activated, or cancelled.
  CardGrant = Data.define(
    :id, :amount_cents, :balance_cents, :email, :status, :merchant_lock, :category_lock,
    :keyword_lock, :allowed_merchants, :allowed_categories, :purpose, :one_time_use,
    :pre_authorization_required, :card_id, :user, :organization, :disbursements, :_client
  ) do
    include Resource

    # @param hash [Hash] API response
    # @param client [Client, nil]
    # @return [CardGrant]
    def self.from_hash(hash, client: nil)
      organization = hash["organization"] ? Organization.from_hash(hash["organization"]) : nil

      new(
        id: hash["id"],
        amount_cents: hash["amount_cents"],
        balance_cents: hash["balance_cents"],
        email: hash["email"],
        status: hash["status"],
        merchant_lock: hash["merchant_lock"],
        category_lock: hash["category_lock"],
        keyword_lock: hash["keyword_lock"],
        allowed_merchants: hash["allowed_merchants"],
        allowed_categories: hash["allowed_categories"],
        purpose: hash["purpose"],
        one_time_use: hash["one_time_use"],
        pre_authorization_required: hash["pre_authorization_required"],
        card_id: hash["card_id"],
        user: hash["user"] ? User.from_hash(hash["user"]) : nil,
        organization:,
        disbursements: hash["disbursements"]&.map { |d| Transfer.from_hash(d, client:, organization:) },
        _client: client
      )
    end

    # Adds funds to this grant.
    # @param amount_cents [Integer]
    # @return [CardGrant]
    def topup!(amount_cents:)
      require_client!
      _client.topup_card_grant(id, amount_cents:)
    end

    # Withdraws funds back to the organization.
    # @param amount_cents [Integer]
    # @return [CardGrant]
    def withdraw!(amount_cents:)
      require_client!
      _client.withdraw_card_grant(id, amount_cents:)
    end

    # Cancels this grant, returning remaining funds.
    # @return [CardGrant]
    def cancel!
      require_client!
      _client.cancel_card_grant(id)
    end

    # Activates a pending grant.
    # @return [CardGrant]
    def activate!
      require_client!
      _client.activate_card_grant(id)
    end

    # Refreshes grant data from the API.
    # @return [CardGrant]
    def reload!
      require_client!
      _client.card_grant(id)
    end

    # Updates grant attributes.
    # @return [CardGrant]
    def update!(**attrs)
      require_client!
      _client.update_card_grant(id, **attrs)
    end

    # @return [Boolean]
    def merchant_lock? = !!merchant_lock

    # @return [Boolean]
    def category_lock? = !!category_lock

    # @return [Boolean]
    def keyword_lock? = !!keyword_lock

    # @return [Boolean]
    def one_time_use? = !!one_time_use

    # @return [Boolean]
    def pre_authorization_required? = !!pre_authorization_required
  end
end
