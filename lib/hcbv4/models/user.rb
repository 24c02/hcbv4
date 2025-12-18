# frozen_string_literal: true

module HCBV4
  # Mailing address for physical card delivery.
  ShippingAddress = Data.define(:address_line1, :address_line2, :city, :state, :country, :postal_code) do
    def self.from_hash(hash)
      return nil unless hash

      new(
        address_line1: hash["address_line1"],
        address_line2: hash["address_line2"],
        city: hash["city"],
        state: hash["state"],
        country: hash["country"],
        postal_code: hash["postal_code"]
      )
    end
  end

  # An HCB user account.
  # @attr_reader id [String] unique user id
  # @attr_reader name [String, nil] display name
  # @attr_reader email [String, nil] email address
  # @attr_reader avatar [String, nil] avatar URL
  # @attr_reader admin [Boolean, nil] HCB admin flag
  # @attr_reader auditor [Boolean, nil] HCB auditor flag
  # @attr_reader birthday [String, nil] ISO date
  # @attr_reader shipping_address [ShippingAddress, nil] mailing address
  class User
    attr_reader :id, :name, :email, :avatar, :admin, :auditor, :birthday, :shipping_address, :_client

    def initialize(id:, name: nil, email: nil, avatar: nil, admin: nil, auditor: nil, birthday: nil, shipping_address: nil, _client: nil)
      @id = id
      @name = name
      @email = email
      @avatar = avatar
      @admin = admin
      @auditor = auditor
      @birthday = birthday
      @shipping_address = shipping_address
      @_client = _client
    end

    # @param hash [Hash] API response
    # @return [User]
    def self.from_hash(hash, client: nil)
      new(
        id: hash["id"],
        name: hash["name"],
        email: hash["email"],
        avatar: hash["avatar"],
        admin: hash["admin"],
        auditor: hash["auditor"],
        birthday: hash["birthday"],
        shipping_address: ShippingAddress.from_hash(hash["shipping_address"]),
        _client: client
      )
    end

    # @return [Boolean] true if user is an HCB admin
    def admin? = !!admin

    # @return [Boolean] true if user is an HCB auditor
    def auditor? = !!auditor

    def ==(other)
      other.is_a?(User) && id == other.id
    end
    alias eql? ==

    def hash
      id.hash
    end
  end
end
