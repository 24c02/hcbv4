# frozen_string_literal: true

module HCBV4
  # A tag applied to a transaction.
  Tag = Data.define(:id, :label, :color, :emoji) do
    # @param hash [Hash] API response
    # @return [Tag]
    def self.from_hash(hash)
      new(id: hash["id"], label: hash["label"], color: hash["color"], emoji: hash["emoji"])
    end
  end
end
