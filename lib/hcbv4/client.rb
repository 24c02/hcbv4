# frozen_string_literal: true

require "faraday"
require "oauth2"
require "json"

module HCBV4
  class Client
    DEFAULT_BASE_URL = "https://hcb.hackclub.com"
    API_PATH = "/api/v4"

    attr_reader :oauth_token, :base_url

    def initialize(oauth_token:, base_url: DEFAULT_BASE_URL)
      @oauth_token = oauth_token
      @base_url = base_url
    end

    def self.from_credentials(client_id:, client_secret:, access_token:, refresh_token:, expires_at: nil,
                              base_url: DEFAULT_BASE_URL)
      oauth_client = OAuth2::Client.new(
        client_id,
        client_secret,
        site: base_url,
        token_url: "/oauth/token"
      )

      token = OAuth2::AccessToken.new(
        oauth_client,
        access_token,
        refresh_token:,
        expires_at:
      )

      new(oauth_token: token, base_url:)
    end

    # ─────────────────────────────────────────────────────────────────────────
    # Users
    # ─────────────────────────────────────────────────────────────────────────

    # Returns the currently authenticated user.
    # @return [User]
    def me
      User.from_hash(get("/user"))
    end

    # Returns a user by id. Admin only.
    # @param id [String] user id
    # @return [User]
    def user(id)
      User.from_hash(get("/users/#{id}"))
    end

    # Returns a user by email address. Admin only.
    # @param email [String]
    # @return [User]
    def user_by_email(email)
      User.from_hash(get("/users/by_email/#{email}"))
    end

    # Returns profile icons the current user can select from.
    # @return [Array<Hash>] icon objects with :id, :url, :name
    def available_icons
      get("/user/available_icons")
    end

    # Returns beacon configuration for the current user.
    # @return [Hash]
    def beacon_config
      get("/user/beacon_config")
    end

    # ─────────────────────────────────────────────────────────────────────────
    # Organizations (Events)
    # ─────────────────────────────────────────────────────────────────────────

    # Returns all organizations the current user belongs to.
    # @param expand [Array<Symbol>] fields to expand (:balance_cents, :reporting, :account_number, :users)
    # @return [Array<Organization>]
    def organizations(expand: [])
      params = { expand: expand.join(",") }.compact.reject { |_, v| v.respond_to?(:empty?) && v.empty? }
      get("/user/organizations", params).map { |h| Organization.from_hash(h, client: self) }
    end

    # Returns an organization by id or slug (fetches from API).
    # @param id_or_slug [String]
    # @param expand [Array<Symbol>] fields to expand
    # @return [Organization]
    def organization(id_or_slug, expand: [])
      params = { expand: expand.join(",") }.compact.reject { |_, v| v.respond_to?(:empty?) && v.empty? }
      Organization.from_hash(get("/organizations/#{id_or_slug}", params), client: self)
    end

    # Stub methods for performing actions without fetching.
    # @!method organization!(id)
    # @!method card_grant!(id)
    # @!method stripe_card!(id)
    # @!method transaction!(id)
    # @!method sponsor!(id)
    # @!method invoice!(id)
    # @!method invitation!(id)
    # @!method receipt!(id)
    %i[Organization CardGrant StripeCard Transaction Sponsor Invoice Invitation Receipt].each do |klass|
      define_method(:"#{klass.to_s.gsub(/([a-z])([A-Z])/, '\1_\2').downcase}!") do |id|
        HCBV4.const_get(klass).of_id(id, client: self)
      end
    end

    # ─────────────────────────────────────────────────────────────────────────
    # Transactions
    # ─────────────────────────────────────────────────────────────────────────

    # Returns paginated transactions for an organization.
    # @param organization_id_or_slug [String]
    # @param limit [Integer, nil] max results per page
    # @param after [String, nil] cursor for pagination (transaction id)
    # @param type [String, nil] filter by transaction type
    # @param filters [Hash] additional filters
    # @param expand [Array<Symbol>] fields to expand (:organization)
    # @return [TransactionList]
    def transactions(organization_id_or_slug, limit: nil, after: nil, type: nil, filters: {}, expand: [])
      params = { limit:, after:, type:, filters:, expand: expand.join(",") }.compact.reject do |_, v|
        v.respond_to?(:empty?) && v.empty?
      end
      pagination_context = {
        type: :organization_transactions,
        organization_id: organization_id_or_slug,
        limit:,
        tx_type: type,
        filters:,
        expand:
      }
      TransactionList.from_hash(get("/organizations/#{organization_id_or_slug}/transactions", params), client: self,
                                                                                                       pagination_context:)
    end

    # Returns a transaction by id.
    # @param id [String]
    # @param event_id [String, nil] organization id for scoping
    # @param expand [Array<Symbol>] fields to expand
    # @return [Transaction]
    def transaction(id, event_id: nil, expand: [])
      params = { event_id:, expand: expand.join(",") }.compact.reject { |_, v| v.respond_to?(:empty?) && v.empty? }
      Transaction.from_hash(get("/transactions/#{id}", params), client: self)
    end

    # Returns transactions missing receipts across all orgs.
    # @param limit [Integer, nil] max results per page
    # @param after [String, nil] cursor for pagination
    # @return [TransactionList]
    def missing_receipt_transactions(limit: nil, after: nil)
      params = { limit:, after: }.compact
      pagination_context = { type: :missing_receipt, limit: }
      TransactionList.from_hash(get("/user/transactions/missing_receipt", params), client: self, pagination_context:)
    end

    # ─────────────────────────────────────────────────────────────────────────
    # Card Grants
    # ─────────────────────────────────────────────────────────────────────────

    # Returns card grants for the current user.
    # @param expand [Array<Symbol>] fields to expand (:user, :organization, :balance_cents, :disbursements)
    # @return [Array<CardGrant>]
    def card_grants(expand: [])
      params = { expand: expand.join(",") }.compact.reject { |_, v| v.respond_to?(:empty?) && v.empty? }
      get("/user/card_grants", params).map { |h| CardGrant.from_hash(h, client: self) }
    end

    # Returns card grants for a specific organization.
    # @param organization_id [String]
    # @param expand [Array<Symbol>] fields to expand
    # @return [Array<CardGrant>]
    def organization_card_grants(organization_id, expand: [])
      params = { expand: expand.join(",") }.compact.reject { |_, v| v.respond_to?(:empty?) && v.empty? }
      get("/organizations/#{organization_id}/card_grants", params).map { |h| CardGrant.from_hash(h, client: self) }
    end

    # Returns a card grant by id.
    # @param id [String]
    # @param expand [Array<Symbol>] fields to expand
    # @return [CardGrant]
    def card_grant(id, expand: [])
      params = { expand: expand.join(",") }.compact.reject { |_, v| v.respond_to?(:empty?) && v.empty? }
      CardGrant.from_hash(get("/card_grants/#{id}", params), client: self)
    end

    # Creates a new card grant (virtual card with spending limits).
    # @param event_id [String] organization id
    # @param amount_cents [Integer] initial funding amount
    # @param email [String] recipient email
    # @param options [Hash] additional options (purpose, merchant_lock, one_time_use, etc.)
    # @return [CardGrant]
    def create_card_grant(event_id:, amount_cents:, email:, **options)
      body = { amount_cents:, email:, **options }
      CardGrant.from_hash(post("/organizations/#{event_id}/card_grants", body), client: self)
    end

    # ─────────────────────────────────────────────────────────────────────────
    # Stripe Cards
    # ─────────────────────────────────────────────────────────────────────────

    # Returns stripe cards for the current user.
    # @param expand [Array<Symbol>] fields to expand (:user, :organization, :total_spent_cents, :balance_available)
    # @return [Array<StripeCard>]
    def stripe_cards(expand: [])
      params = { expand: expand.join(",") }.compact.reject { |_, v| v.respond_to?(:empty?) && v.empty? }
      get("/user/cards", params).map { |h| StripeCard.from_hash(h, client: self) }
    end

    # Returns stripe cards for a specific organization.
    # @param organization_id [String]
    # @param expand [Array<Symbol>] fields to expand
    # @return [Array<StripeCard>]
    def organization_stripe_cards(organization_id, expand: [])
      params = { expand: expand.join(",") }.compact.reject { |_, v| v.respond_to?(:empty?) && v.empty? }
      get("/organizations/#{organization_id}/cards", params).map { |h| StripeCard.from_hash(h, client: self) }
    end

    # Returns a stripe card by id.
    # @param id [String]
    # @param expand [Array<Symbol>] fields to expand
    # @return [StripeCard]
    def stripe_card(id, expand: [])
      params = { expand: expand.join(",") }.compact.reject { |_, v| v.respond_to?(:empty?) && v.empty? }
      StripeCard.from_hash(get("/cards/#{id}", params), client: self)
    end

    # Creates a new stripe card (virtual or physical).
    # @param organization_id [String]
    # @param card_type [String] "virtual" or "physical"
    # @param options [Hash] additional options (name, design_id, shipping address, etc.)
    # @return [StripeCard]
    def create_stripe_card(organization_id:, card_type:, **options)
      body = { card: { organization_id:, card_type:, **options } }
      StripeCard.from_hash(post("/cards", body), client: self)
    end

    # Returns available card designs for physical card personalization.
    # @param event_id [String, nil] organization id to filter designs
    # @return [Array<CardDesign>] available designs
    def card_designs(event_id: nil)
      params = event_id ? { event_id: } : {}
      get("/cards/card_designs", params).map { |h| CardDesign.from_hash(h) }
    end

    # ─────────────────────────────────────────────────────────────────────────
    # Invoices
    # ─────────────────────────────────────────────────────────────────────────

    # Returns invoices for an organization.
    # @param event_id [String] organization id
    # @return [Array<Invoice>]
    def invoices(event_id:)
      get("/organizations/#{event_id}/invoices").map { |h| Invoice.from_hash(h, client: self) }
    end

    # Returns an invoice by id.
    # @param id [String]
    # @return [Invoice]
    def invoice(id)
      Invoice.from_hash(get("/invoices/#{id}"), client: self)
    end

    # Creates an invoice for a sponsor.
    # @param event_id [String] organization id
    # @param sponsor_id [String]
    # @param due_date [String] ISO date (YYYY-MM-DD)
    # @param item_description [String]
    # @param item_amount [Integer] amount in cents
    # @return [Invoice]
    def create_invoice(event_id:, sponsor_id:, due_date:, item_description:, item_amount:)
      body = { organization_id: event_id, sponsor_id:, invoice: { due_date:, item_description:, item_amount: } }
      Invoice.from_hash(post("/invoices", body), client: self)
    end

    # ─────────────────────────────────────────────────────────────────────────
    # Sponsors
    # ─────────────────────────────────────────────────────────────────────────

    # Returns sponsors for an organization.
    # @param event_id [String] organization id
    # @return [Array<Sponsor>]
    def sponsors(event_id:)
      get("/organizations/#{event_id}/sponsors").map { |h| Sponsor.from_hash(h, client: self) }
    end

    # Returns a sponsor by id.
    # @param id [String]
    # @return [Sponsor]
    def sponsor(id)
      Sponsor.from_hash(get("/sponsors/#{id}"), client: self)
    end

    # Creates a sponsor for invoicing.
    # @param event_id [String] organization id
    # @param name [String] sponsor/company name
    # @param contact_email [String] billing email
    # @param address [Hash] address fields (address_line1, address_city, address_state, etc.)
    # @return [Sponsor]
    def create_sponsor(event_id:, name:, contact_email:, **address)
      body = { organization_id: event_id, sponsor: { name:, contact_email:, **address } }
      Sponsor.from_hash(post("/sponsors", body), client: self)
    end

    # ─────────────────────────────────────────────────────────────────────────
    # Disbursements (Transfers)
    # ─────────────────────────────────────────────────────────────────────────

    # Transfers funds from one organization to another.
    # @param event_id [String] source organization id
    # @param to_organization_id [String] destination organization id
    # @param amount_cents [Integer]
    # @param name [String] transfer description
    # @return [Transfer]
    def create_disbursement(event_id:, to_organization_id:, amount_cents:, name:)
      body = { to_organization_id:, amount_cents:, name: }
      organization = Organization.of_id(event_id, client: self)
      Transfer.from_hash(post("/organizations/#{event_id}/transfers", body), client: self, organization:)
    end

    # ─────────────────────────────────────────────────────────────────────────
    # ACH Transfers
    # ─────────────────────────────────────────────────────────────────────────

    # Initiates an ACH bank transfer.
    # @param event_id [String] organization id
    # @param routing_number [String] 9-digit ABA routing number
    # @param account_number [String] bank account number
    # @param recipient_name [String] name on the bank account
    # @param amount_money [String] amount as decimal string (e.g., "100.00")
    # @param payment_for [String] payment description/memo
    # @param options [Hash] additional options
    # @return [Hash]
    def create_ach_transfer(event_id:, routing_number:, account_number:, recipient_name:, amount_money:, payment_for:,
                            **options)
      body = {
        ach_transfer: {
          routing_number:, account_number:, recipient_name:, amount_money:, payment_for:, **options
        }
      }
      post("/organizations/#{event_id}/ach_transfers", body)
    end

    # ─────────────────────────────────────────────────────────────────────────
    # Donations
    # ─────────────────────────────────────────────────────────────────────────

    # Records an in-person donation (cash, check, etc.).
    # @param event_id [String] organization id
    # @param amount_cents [Integer]
    # @param options [Hash] donor info (name, email, anonymous, tax_deductible, fee_covered)
    # @return [Donation] returns only the donation id
    def create_donation(event_id:, amount_cents:, **options)
      body = { amount_cents:, **options }
      Donation.from_hash(post("/organizations/#{event_id}/donations", body))
    end

    # ─────────────────────────────────────────────────────────────────────────
    # Receipts
    # ─────────────────────────────────────────────────────────────────────────

    # Returns receipts, optionally filtered by transaction.
    # @param transaction_id [String, nil] filter to a specific transaction
    # @return [Array<Receipt>]
    def receipts(transaction_id: nil)
      params = transaction_id ? { transaction_id: } : {}
      get("/receipts", params).map { |h| Receipt.from_hash(h, client: self) }
    end

    # Uploads a receipt image.
    # @param file [File] receipt file
    # @param transaction_id [String, nil] attach to a transaction, or nil for receipt bin
    # @return [Receipt]
    def create_receipt(file:, transaction_id: nil)
      body = { file:, transaction_id: }.compact
      Receipt.from_hash(post("/receipts", body), client: self)
    end

    # ─────────────────────────────────────────────────────────────────────────
    # Invitations
    # ─────────────────────────────────────────────────────────────────────────

    # Returns pending invitations for the current user.
    # @return [Array<Invitation>]
    def invitations
      get("/user/invitations").map { |h| Invitation.from_hash(h, client: self) }
    end

    # Returns an invitation by id.
    # @param id [String]
    # @return [Invitation]
    def invitation(id)
      Invitation.from_hash(get("/user/invitations/#{id}"), client: self)
    end

    # Invites a user to join an organization.
    # @param event_id [String] organization id
    # @param email [String] invitee email
    # @param role [String, nil] "member" or "manager"
    # @param enable_spending_controls [Boolean, nil] enable spending controls
    # @param initial_control_allowance_amount [Integer, nil] initial allowance in cents
    # @return [Invitation]
    def create_invitation(event_id:, email:, role: nil, enable_spending_controls: nil,
                          initial_control_allowance_amount: nil)
      body = { event_id:, email:, role:, enable_spending_controls:, initial_control_allowance_amount: }.compact
      Invitation.from_hash(post("/user/invitations", body), client: self)
    end

    # ─────────────────────────────────────────────────────────────────────────
    # Stripe Terminal
    # ─────────────────────────────────────────────────────────────────────────

    # Returns a connection token for Stripe Terminal hardware.
    # @return [Hash] token data
    def terminal_connection_token
      get("/stripe_terminal_connection_token")
    end

    # ─────────────────────────────────────────────────────────────────────────
    # Raw HTTP methods
    # ─────────────────────────────────────────────────────────────────────────

    def get(path, params = {})
      request(:get, path, params:)
    end

    def post(path, body = {})
      request(:post, path, body:)
    end

    def patch(path, body = {})
      request(:patch, path, body:)
    end

    def delete(path)
      request(:delete, path)
    end

    # ─────────────────────────────────────────────────────────────────────────
    # Resource instance methods (called via resource objects)
    # ─────────────────────────────────────────────────────────────────────────

    # @!visibility private
    def update_card_grant(id, **attributes)
      CardGrant.from_hash(patch("/card_grants/#{id}", attributes), client: self)
    end

    # @!visibility private
    def topup_card_grant(id, amount_cents:)
      CardGrant.from_hash(post("/card_grants/#{id}/topup", { amount_cents: }), client: self)
    end

    # @!visibility private
    def withdraw_card_grant(id, amount_cents:)
      CardGrant.from_hash(post("/card_grants/#{id}/withdraw", { amount_cents: }), client: self)
    end

    # @!visibility private
    def cancel_card_grant(id)
      CardGrant.from_hash(post("/card_grants/#{id}/cancel"), client: self)
    end

    # @!visibility private
    def activate_card_grant(id)
      CardGrant.from_hash(post("/card_grants/#{id}/activate"), client: self)
    end

    # @!visibility private
    def update_stripe_card(id, status:, last4: nil)
      params = { status:, last4: }.compact
      StripeCard.from_hash(patch("/cards/#{id}", params), client: self)
    end

    # @!visibility private
    def cancel_stripe_card(id)
      post("/cards/#{id}/cancel")
    end

    # @!visibility private
    def stripe_card_ephemeral_keys(id, nonce:, stripe_version: nil)
      params = { nonce:, stripe_version: }.compact
      get("/cards/#{id}/ephemeral_keys", params)
    end

    # @!visibility private
    def stripe_card_transactions(id, limit: nil, after: nil, missing_receipts: nil)
      params = { limit:, after:, missing_receipts: }.compact
      pagination_context = { type: :stripe_card_transactions, card_id: id, limit:, missing_receipts: }
      TransactionList.from_hash(get("/cards/#{id}/transactions", params), client: self, pagination_context:)
    end

    # @!visibility private
    def accept_invitation(id)
      Invitation.from_hash(post("/user/invitations/#{id}/accept"), client: self)
    end

    # @!visibility private
    def reject_invitation(id)
      Invitation.from_hash(post("/user/invitations/#{id}/reject"), client: self)
    end

    # @!visibility private
    def delete_receipt(id)
      delete("/receipts/#{id}")
    end

    # @!visibility private
    def update_transaction(id, event_id:, memo:)
      Transaction.from_hash(patch("/organizations/#{event_id}/transactions/#{id}", { memo: }), client: self)
    end

    # @!visibility private
    def memo_suggestions(event_id:, transaction_id:)
      get("/organizations/#{event_id}/transactions/#{transaction_id}/memo_suggestions")
    end

    # @!visibility private
    def organization_followers(id_or_slug)
      data = get("/organizations/#{id_or_slug}/followers")
      data["followers"]&.map { |h| User.from_hash(h) } || []
    end

    # @!visibility private
    def sub_organizations(id_or_slug)
      get("/organizations/#{id_or_slug}/sub_organizations").map { |h| Organization.from_hash(h, client: self) }
    end

    # @!visibility private
    def create_sub_organization(parent_id_or_slug, name:, email:, cosigner_email: nil, country: nil, scoped_tags: nil)
      body = { name:, email:, cosigner_email:, country:, scoped_tags: }.compact
      Organization.from_hash(post("/organizations/#{parent_id_or_slug}/sub_organizations", body), client: self)
    end

    # @!visibility private
    def comments(organization_id:, transaction_id:)
      get("/organizations/#{organization_id}/transactions/#{transaction_id}/comments").map { |h| Comment.from_hash(h) }
    end

    # @!visibility private
    def create_comment(organization_id:, transaction_id:, content:, admin_only: false, file: nil)
      body = { content:, admin_only:, file: }.compact
      Comment.from_hash(post("/organizations/#{organization_id}/transactions/#{transaction_id}/comments", body))
    end

    private

    def request(method, path, params: nil, body: nil)
      refresh_token_if_needed!

      response = connection.public_send(method, "#{API_PATH}#{path}") do |req|
        req.params = params if params
        req.body = body.to_json if body
        req.headers["Authorization"] = "Bearer #{oauth_token.token}"
      end

      handle_response(response)
    end

    def refresh_token_if_needed!
      return unless oauth_token.respond_to?(:expired?)
      return unless oauth_token.expired?

      @oauth_token = oauth_token.refresh!
    end

    def connection
      @connection ||= Faraday.new(url: base_url) do |f|
        f.request :json
        f.response :json
        f.headers["Content-Type"] = "application/json"
        f.headers["Accept"] = "application/json"
      end
    end

    def handle_response(response)
      case response.status
      when 200..299
        response.body
      when 400
        raise_api_error(response, BadRequestError)
      when 401
        raise_api_error(response, UnauthorizedError)
      when 403
        raise_api_error(response, ForbiddenError)
      when 404
        raise_api_error(response, NotFoundError)
      when 422
        raise_api_error(response, UnprocessableEntityError)
      when 429
        raise_api_error(response, RateLimitError)
      when 500..599
        raise_api_error(response, ServerError)
      else
        raise_api_error(response, APIError)
      end
    end

    def raise_api_error(response, error_class)
      body = response.body || {}
      error_code = body["error"]
      messages = Array(body["messages"])

      error_class = case error_code
                    when "invalid_operation" then InvalidOperationError
                    when "invalid_user" then InvalidUserError
                    else error_class
                    end

      raise error_class.new(
        messages.first || body["error"] || "API error",
        status: response.status,
        error_code:,
        messages:
      )
    end
  end
end
