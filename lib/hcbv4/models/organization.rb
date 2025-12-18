# frozen_string_literal: true

module HCBV4
  # An HCB organization (also called an "event").
  # Holds funds, issues cards, and manages transactions.
  Organization = Data.define(
    :id, :name, :slug, :country, :icon, :background_image, :created_at,
    :parent_id, :donation_page_available, :playground_mode,
    :playground_mode_meeting_requested, :transparent, :fee_percentage,
    :balance_cents, :fee_balance_cents, :total_spent_cents, :total_raised_cents,
    :account_number, :routing_number, :swift_bic_code, :users, :_client
  ) do
    include Resource

    # @param hash [Hash] API response
    # @param client [Client, nil] for making subsequent requests
    # @return [Organization]
    def self.from_hash(hash, client: nil)
      balances = hash["balances"] || {}
      new(
        id: hash["id"],
        name: hash["name"],
        slug: hash["slug"],
        country: hash["country"],
        icon: hash["icon"],
        background_image: hash["background_image"],
        created_at: hash["created_at"],
        parent_id: hash["parent_id"],
        donation_page_available: hash["donation_page_available"],
        playground_mode: hash["playground_mode"],
        playground_mode_meeting_requested: hash["playground_mode_meeting_requested"],
        transparent: hash["transparent"],
        fee_percentage: hash["fee_percentage"],
        balance_cents: hash["balance_cents"],
        fee_balance_cents: hash["fee_balance_cents"],
        total_spent_cents: hash["total_spent_cents"],
        total_raised_cents: hash["total_raised_cents"],
        account_number: hash["account_number"],
        routing_number: hash["routing_number"],
        swift_bic_code: hash["swift_bic_code"],
        users: hash["users"]&.map { |u| OrganizationUser.from_hash(u) },
        _client: client
      )
    end

    # Refreshes organization data from the API.
    # @return [Organization]
    def reload! = (require_client!; _client.organization(id))

    # @return [Array<CardGrant>]
    def card_grants(expand: []) = (require_client!; _client.organization_card_grants(id, expand:))

    # @return [Array<StripeCard>]
    def stripe_cards(expand: []) = (require_client!; _client.organization_stripe_cards(id, expand:))

    # @return [Array<Invoice>]
    def invoices = (require_client!; _client.invoices(event_id: id))

    # @return [Array<Sponsor>]
    def sponsors = (require_client!; _client.sponsors(event_id: id))

    # @return [Array<User>] users following this transparent org
    def followers = (require_client!; _client.organization_followers(id))

    # Returns paginated transactions.
    # @return [TransactionList]
    def transactions(**opts)
      require_client!
      _client.transactions(id, **opts)
    end

    # @return [Array<Organization>] child organizations
    def sub_organizations
      require_client!
      _client.sub_organizations(id)
    end

    # Creates a card grant for this organization.
    # @return [CardGrant]
    def create_card_grant(amount_cents:, email:, **opts)
      require_client!
      _client.create_card_grant(event_id: id, amount_cents:, email:, **opts)
    end

    # Creates an invoice for a sponsor.
    # @return [Invoice]
    def create_invoice(sponsor_id:, due_date:, item_description:, item_amount:)
      require_client!
      _client.create_invoice(event_id: id, sponsor_id:, due_date:, item_description:, item_amount:)
    end

    # Creates a sponsor record.
    # @return [Sponsor]
    def create_sponsor(name:, contact_email:, **address)
      require_client!
      _client.create_sponsor(event_id: id, name:, contact_email:, **address)
    end

    # Transfers funds to another organization.
    # @return [Transfer]
    def create_disbursement(to_organization_id:, amount_cents:, name:)
      require_client!
      _client.create_disbursement(event_id: id, to_organization_id:, amount_cents:, name:)
    end

    # Initiates an ACH bank transfer.
    # @return [Hash]
    def create_ach_transfer(routing_number:, account_number:, recipient_name:, amount_money:, payment_for:, **opts)
      require_client!
      _client.create_ach_transfer(event_id: id, routing_number:, account_number:, recipient_name:, amount_money:, payment_for:, **opts)
    end

    # Records an in-person donation.
    # @return [Donation]
    def create_donation(amount_cents:, **opts)
      require_client!
      _client.create_donation(event_id: id, amount_cents:, **opts)
    end

    # Invites a user to this organization.
    # @return [Invitation]
    def create_invitation(email:, role: nil, **opts)
      require_client!
      _client.create_invitation(event_id: id, email:, role:, **opts)
    end

    # Creates a sub-organization under this one.
    # @return [Organization]
    def create_sub_organization(name:, email:, **opts)
      require_client!
      _client.create_sub_organization(id, name:, email:, **opts)
    end

    # @return [Boolean]
    def donation_page_available? = !!donation_page_available

    # @return [Boolean]
    def playground_mode? = !!playground_mode

    # @return [Boolean]
    def playground_mode_meeting_requested? = !!playground_mode_meeting_requested

    # @return [Boolean]
    def transparent? = !!transparent
  end
end
