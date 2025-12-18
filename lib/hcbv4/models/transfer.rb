# frozen_string_literal: true

module HCBV4
  # An inter-organization fund transfer.
  # @attr_reader transaction_id [String, nil] associated ledger entry
  # @attr_reader from [Organization, nil] source organization
  # @attr_reader to [Organization, nil] destination organization
  # @attr_reader sender [User, nil] user who initiated the transfer
  # @attr_reader card_grant_id [String, nil] associated card grant
  # @attr_reader organization [Organization, nil] organization context for fetching transaction
  class Transfer < BaseTransactionDetail
    attr_reader :transaction_id, :from, :to, :sender, :card_grant_id, :organization, :_client

    def initialize(id:, amount_cents: nil, memo: nil, status: nil, transaction_id: nil, from: nil, to: nil,
                   sender: nil, card_grant_id: nil, organization: nil, client: nil)
      super(id:, amount_cents:, memo:, status:)
      @transaction_id = transaction_id
      @from = from
      @to = to
      @sender = sender
      @card_grant_id = card_grant_id
      @organization = organization
      @_client = client
    end

    # Fetches the associated transaction.
    # @return [Transaction]
    def transaction
      raise Error, "No client attached to this Transfer" unless _client
      raise Error, "No transaction_id on this Transfer" unless transaction_id

      _client.transaction(transaction_id)
    end

    # Stubs a Transaction with the associated transaction ID and organization.
    # @return [Transaction]
    def transaction!
      raise Error, "No client attached to this Transfer" unless _client
      raise Error, "No transaction_id on this Transfer" unless transaction_id

      Transaction.of_id(transaction_id, client: _client, organization:)
    end

    # @param hash [Hash] API response
    # @param client [Client, nil]
    # @param organization [Organization, nil] organization context
    # @return [Transfer]
    def self.from_hash(hash, client: nil, organization: nil)
      new(
        id: hash["id"],
        amount_cents: hash["amount_cents"],
        memo: hash["memo"],
        status: hash["status"],
        transaction_id: hash["transaction_id"],
        from: hash["from"] ? Organization.from_hash(hash["from"]) : nil,
        to: hash["to"] ? Organization.from_hash(hash["to"]) : nil,
        sender: hash["sender"] ? User.from_hash(hash["sender"]) : nil,
        card_grant_id: hash["card_grant_id"],
        organization:,
        client:
      )
    end
  end

  # Alias for Transfer.
  Disbursement = Transfer
end
