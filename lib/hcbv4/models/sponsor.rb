# frozen_string_literal: true

module HCBV4
  # A sponsor or donor contact for invoicing.
  Sponsor = Data.define(
    :id, :name, :slug, :contact_email, :created_at, :event_id, :stripe_customer_id,
    :address_line1, :address_line2, :address_city, :address_state,
    :address_postal_code, :address_country, :_client
  ) do
    include Resource

    # @param hash [Hash] API response
    # @param client [Client, nil]
    # @return [Sponsor]
    def self.from_hash(hash, client: nil)
      new(
        id: hash["id"], name: hash["name"], slug: hash["slug"], contact_email: hash["contact_email"],
        created_at: hash["created_at"], event_id: hash["event_id"], stripe_customer_id: hash["stripe_customer_id"],
        address_line1: hash["address_line1"], address_line2: hash["address_line2"], address_city: hash["address_city"],
        address_state: hash["address_state"], address_postal_code: hash["address_postal_code"],
        address_country: hash["address_country"],
        _client: client
      )
    end

    # Refreshes sponsor data from the API.
    # @return [Sponsor]
    def reload! = (require_client!; _client.sponsor(id))

    # Creates an invoice for this sponsor.
    # @param due_date [String] ISO date (YYYY-MM-DD)
    # @param item_description [String]
    # @param item_amount [Integer] amount in cents
    # @return [Invoice]
    def create_invoice(due_date:, item_description:, item_amount:)
      require_client!
      _client.create_invoice(event_id:, sponsor_id: id, due_date:, item_description:, item_amount:)
    end
  end
end
