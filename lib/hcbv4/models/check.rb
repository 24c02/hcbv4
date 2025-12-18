# frozen_string_literal: true

module HCBV4
  # Mailed check payment details.
  class Check < BaseTransactionDetail
    attr_reader :address_city, :address_line1, :address_line2, :address_state, :address_zip,
                :recipient_email, :check_number, :recipient_name, :payment_for, :sender

    def initialize(id:, amount_cents: nil, memo: nil, status: nil, address_city: nil, address_line1: nil,
                   address_line2: nil, address_state: nil, address_zip: nil, recipient_email: nil,
                   check_number: nil, recipient_name: nil, payment_for: nil, sender: nil)
      super(id:, amount_cents:, memo:, status:)
      @address_city = address_city
      @address_line1 = address_line1
      @address_line2 = address_line2
      @address_state = address_state
      @address_zip = address_zip
      @recipient_email = recipient_email
      @check_number = check_number
      @recipient_name = recipient_name
      @payment_for = payment_for
      @sender = sender
    end

    # @param hash [Hash] API response
    # @return [Check]
    def self.from_hash(hash)
      new(
        id: hash["id"],
        amount_cents: hash["amount_cents"],
        memo: hash["memo"],
        status: hash["status"],
        address_city: hash["address_city"],
        address_line1: hash["address_line1"],
        address_line2: hash["address_line2"],
        address_state: hash["address_state"],
        address_zip: hash["address_zip"],
        recipient_email: hash["recipient_email"],
        check_number: hash["check_number"],
        recipient_name: hash["recipient_name"],
        payment_for: hash["payment_for"],
        sender: hash["sender"] ? User.from_hash(hash["sender"]) : nil
      )
    end
  end

  # Deposited check details.
  class CheckDeposit < BaseTransactionDetail
    attr_reader :front_url, :back_url, :submitter

    def initialize(id:, amount_cents: nil, memo: nil, status: nil, front_url: nil, back_url: nil, submitter: nil)
      super(id:, amount_cents:, memo:, status:)
      @front_url = front_url
      @back_url = back_url
      @submitter = submitter
    end

    # @param hash [Hash] API response
    # @return [CheckDeposit]
    def self.from_hash(hash)
      new(
        id: hash["id"],
        amount_cents: hash["amount_cents"],
        memo: hash["memo"],
        status: hash["status"],
        front_url: hash["front_url"],
        back_url: hash["back_url"],
        submitter: hash["submitter"] ? User.from_hash(hash["submitter"]) : nil
      )
    end
  end
end
