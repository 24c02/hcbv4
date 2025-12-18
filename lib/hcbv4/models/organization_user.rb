# frozen_string_literal: true

module HCBV4
  # A user with organization-specific membership info (role, join date).
  # Returned when expanding :users on an organization.
  # @attr_reader joined_at [String, nil] ISO timestamp when user joined the org
  # @attr_reader role [String, nil] "member" or "manager"
  class OrganizationUser < User
    attr_reader :joined_at, :role

    def initialize(id:, name: nil, email: nil, avatar: nil, admin: nil, auditor: nil, birthday: nil,
                   shipping_address: nil, joined_at: nil, role: nil)
      super(id:, name:, email:, avatar:, admin:, auditor:, birthday:, shipping_address:)
      @joined_at = joined_at
      @role = role
    end

    # @param hash [Hash] API response
    # @return [OrganizationUser]
    def self.from_hash(hash)
      new(
        id: hash["id"],
        name: hash["name"],
        email: hash["email"],
        avatar: hash["avatar"],
        admin: hash["admin"],
        auditor: hash["auditor"],
        joined_at: hash["joined_at"],
        role: hash["role"]
      )
    end
  end
end
