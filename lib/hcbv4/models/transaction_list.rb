# frozen_string_literal: true

module HCBV4
  # Paginated list of transactions. Implements Enumerable.
  TransactionList = Data.define(:data, :total_count, :has_more, :_client, :_pagination_context) do
    include Resource
    include Enumerable

    # @param hash [Hash] API response
    # @param client [Client, nil]
    # @param pagination_context [Hash, nil] internal pagination state
    # @return [TransactionList]
    def self.from_hash(hash, client: nil, pagination_context: nil)
      new(
        data: hash["data"]&.map { |t| Transaction.from_hash(t, client:) } || [],
        total_count: hash["total_count"],
        has_more: hash["has_more"],
        _client: client,
        _pagination_context: pagination_context
      )
    end

    # Iterates over transactions in this page.
    # @yield [Transaction]
    def each(&block)
      return enum_for(:each) unless block_given?

      data.each(&block)
    end

    # @return [Boolean] true if more pages are available
    def has_more? = !!has_more

    # Fetches the next page of transactions.
    # @return [TransactionList, nil]
    def next_page
      return nil unless has_more? && _client && _pagination_context

      case _pagination_context[:type]
      when :organization_transactions
        _client.transactions(
          _pagination_context[:organization_id],
          limit: _pagination_context[:limit],
          after: data.last&.id,
          type: _pagination_context[:tx_type],
          filters: _pagination_context[:filters],
          expand: _pagination_context[:expand] || []
        )
      when :missing_receipt
        _client.missing_receipt_transactions(
          limit: _pagination_context[:limit],
          after: data.last&.id
        )
      when :stripe_card_transactions
        _client.stripe_card_transactions(
          _pagination_context[:card_id],
          limit: _pagination_context[:limit],
          after: data.last&.id,
          missing_receipts: _pagination_context[:missing_receipts]
        )
      end
    end

    # Iterates through all pages.
    # @yield [TransactionList] each page
    def each_page
      return enum_for(:each_page) unless block_given?

      page = self
      loop do
        yield page
        break unless page.has_more?

        page = page.next_page
        break if page.nil?
      end
    end

    # Lazily iterates through all transactions across pages.
    # @param max_pages [Integer, nil] limit number of pages fetched
    # @yield [Transaction]
    def auto_paginate(max_pages: nil, &block)
      return enum_for(:auto_paginate, max_pages:) unless block_given?

      pages = 0
      each_page do |page|
        page.each(&block)
        pages += 1
        break if max_pages && pages >= max_pages
      end
    end

    # Collects all transactions into an array.
    # @param max_pages [Integer] safety limit (default 100)
    # @return [Array<Transaction>]
    def all(max_pages: 100)
      auto_paginate(max_pages:).to_a
    end
  end
end
