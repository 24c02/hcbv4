# frozen_string_literal: true

module HCBV4
  # A physical card design for personalization.
  CardDesign = Data.define(:id, :name, :color, :status, :unlisted, :common, :logo_url) do
    # @param hash [Hash] API response
    # @return [CardDesign]
    def self.from_hash(hash)
      new(
        id: hash["id"], name: hash["name"], color: hash["color"], status: hash["status"],
        unlisted: hash["unlisted"], common: hash["common"], logo_url: hash["logo_url"]
      )
    end

    # @return [Boolean] true if not shown in public picker
    def unlisted? = !!unlisted

    # @return [Boolean] true if available to all orgs
    def common? = !!common
  end
end
