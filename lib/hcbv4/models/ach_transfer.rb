# frozen_string_literal: true

module HCBV4
  # ACH bank transfer details.
  # @attr_reader recipient_name [String, nil]
  # @attr_reader recipient_email [String, nil]
  # @attr_reader bank_name [String, nil]
  # @attr_reader account_number_last4 [String, nil] last 4 digits (requires permission)
  # @attr_reader routing_number [String, nil] (requires permission)
  # @attr_reader payment_for [String, nil] payment memo
  # @attr_reader sender [User, nil] user who initiated the transfer
  class ACHTransfer < BaseTransactionDetail
    attr_reader :recipient_name, :recipient_email, :bank_name, :account_number_last4, :routing_number, :payment_for,
                :sender

    def initialize(id:, amount_cents: nil, memo: nil, status: nil, recipient_name: nil, recipient_email: nil,
                   bank_name: nil, account_number_last4: nil, routing_number: nil, payment_for: nil, sender: nil)
      super(id:, amount_cents:, memo:, status:)
      @recipient_name = recipient_name
      @recipient_email = recipient_email
      @bank_name = bank_name
      @account_number_last4 = account_number_last4
      @routing_number = routing_number
      @payment_for = payment_for
      @sender = sender
    end

    # @param hash [Hash] API response
    # @return [ACHTransfer]
    def self.from_hash(hash)
      new(
        id: hash["id"],
        amount_cents: hash["amount_cents"],
        memo: hash["memo"],
        status: hash["status"],
        recipient_name: hash["recipient_name"],
        recipient_email: hash["recipient_email"],
        bank_name: hash["bank_name"],
        account_number_last4: hash["account_number_last4"],
        routing_number: hash["routing_number"],
        payment_for: hash["payment_for"],
        sender: hash["sender"] ? User.from_hash(hash["sender"]) : nil
      )
    end
  end

  AchTransferDetails = ACHTransfer
end
