# frozen_string_literal: true

module HCBV4
  # A financial transaction on an organization's ledger.
  # Contains type-specific details (card_charge, donation, transfer, etc.).
  Transaction = Data.define(
    :id, :date, :amount_cents, :memo, :has_custom_memo, :pending, :declined, :tags,
    :code, :missing_receipt, :lost_receipt, :appearance,
    :card_charge, :donation, :expense_payout, :invoice, :check, :transfer,
    :ach_transfer, :check_deposit, :organization, :_client
  ) do
    include Resource
    include TransactionType

    # @param hash [Hash] API response
    # @param client [Client, nil]
    # @return [Transaction]
    def self.from_hash(hash, client: nil)
      organization = hash["organization"] ? Organization.from_hash(hash["organization"]) : nil

      new(
        id: hash["id"],
        date: hash["date"],
        amount_cents: hash["amount_cents"],
        memo: hash["memo"],
        has_custom_memo: hash["has_custom_memo"],
        pending: hash["pending"],
        declined: hash["declined"],
        tags: hash["tags"]&.map { |t| Tag.from_hash(t) },
        code: hash["code"],
        missing_receipt: hash["missing_receipt"],
        lost_receipt: hash["lost_receipt"],
        appearance: hash["appearance"],
        card_charge: hash["card_charge"] ? CardCharge.from_hash(hash["card_charge"]) : nil,
        donation: hash["donation"] ? DonationTransaction.from_hash(hash["donation"]) : nil,
        expense_payout: hash["expense_payout"] ? ExpensePayout.from_hash(hash["expense_payout"]) : nil,
        invoice: hash["invoice"] ? InvoiceTransaction.from_hash(hash["invoice"]) : nil,
        check: hash["check"] ? Check.from_hash(hash["check"]) : nil,
        transfer: hash["transfer"] ? Transfer.from_hash(hash["transfer"], client:, organization:) : nil,
        ach_transfer: hash["ach_transfer"] ? ACHTransfer.from_hash(hash["ach_transfer"]) : nil,
        check_deposit: hash["check_deposit"] ? CheckDeposit.from_hash(hash["check_deposit"]) : nil,
        organization:,
        _client: client
      )
    end

    # Returns the transaction type as a symbol.
    # @return [Symbol] :card_charge, :donation, :transfer, :ach_transfer, etc.
    def type
      return :card_charge if card_charge
      return :donation if donation
      return :expense_payout if expense_payout
      return :invoice if invoice
      return :check if check
      return :transfer if transfer
      return :ach_transfer if ach_transfer
      return :check_deposit if check_deposit

      :unknown
    end

    # Returns the type-specific detail object.
    # @return [CardCharge, DonationTransaction, Transfer, ACHTransfer, Check, nil]
    def details
      card_charge || donation || expense_payout || invoice || check || transfer || ach_transfer || check_deposit
    end

    # @return [Array<Comment>]
    def comments
      require_client!
      _client.comments(organization_id: organization&.id, transaction_id: id)
    end

    # @return [Array<Receipt>]
    def receipts
      require_client!
      _client.receipts(transaction_id: id)
    end

    # Refreshes transaction data from the API.
    # @return [Transaction]
    def reload!
      require_client!
      _client.transaction(id)
    end

    # Updates the transaction memo.
    # @param memo [String]
    # @return [Transaction]
    def update!(memo:)
      require_client!
      _client.update_transaction(id, event_id: organization&.id, memo:)
    end

    # Adds a comment to this transaction.
    # @param content [String]
    # @param admin_only [Boolean]
    # @param file [File, nil]
    # @return [Comment]
    def add_comment(content:, admin_only: false, file: nil)
      require_client!
      _client.create_comment(organization_id: organization&.id, transaction_id: id, content:, admin_only:, file:)
    end

    # Uploads a receipt and attaches it to this transaction.
    # @param file [File]
    # @return [Receipt]
    def add_receipt(file:)
      require_client!
      _client.create_receipt(file:, transaction_id: id)
    end

    # Returns memo autocomplete suggestions based on past transaction memos.
    # @return [Array<String>] suggested memo strings
    def memo_suggestions
      require_client!
      _client.memo_suggestions(event_id: organization&.id, transaction_id: id)
    end

    # @return [Boolean]
    def has_custom_memo? = !!has_custom_memo

    # @return [Boolean]
    def missing_receipt? = !!missing_receipt

    # @return [Boolean]
    def lost_receipt? = !!lost_receipt
  end
end
