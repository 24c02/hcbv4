# frozen_string_literal: true

module HCBV4
  # An uploaded receipt image attached to a transaction.
  Receipt = Data.define(:id, :created_at, :url, :preview_url, :filename, :uploader, :_client) do
    include Resource

    # @param hash [Hash] API response
    # @param client [Client, nil]
    # @return [Receipt]
    def self.from_hash(hash, client: nil)
      new(
        id: hash["id"],
        created_at: hash["created_at"],
        url: hash["url"],
        preview_url: hash["preview_url"],
        filename: hash["filename"],
        uploader: hash["uploader"] ? User.from_hash(hash["uploader"]) : nil,
        _client: client
      )
    end

    # Deletes this receipt.
    # @return [nil]
    def delete!
      require_client!
      _client.delete_receipt(id)
    end
  end
end
