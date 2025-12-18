# frozen_string_literal: true

module HCBV4
  # An invitation to join an organization.
  Invitation = Data.define(:id, :created_at, :accepted, :role, :sender, :organization, :_client) do
    include Resource

    # @param hash [Hash] API response
    # @param client [Client, nil]
    # @return [Invitation]
    def self.from_hash(hash, client: nil)
      new(
        id: hash["id"],
        created_at: hash["created_at"],
        accepted: hash["accepted"],
        role: hash["role"],
        sender: hash["sender"] ? User.from_hash(hash["sender"]) : nil,
        organization: hash["organization"] ? Organization.from_hash(hash["organization"]) : nil,
        _client: client
      )
    end

    # Accepts this invitation.
    # @return [Invitation]
    def accept! = (require_client!; _client.accept_invitation(id))

    # Rejects this invitation.
    # @return [Invitation]
    def reject! = (require_client!; _client.reject_invitation(id))

    # Refreshes invitation data from the API.
    # @return [Invitation]
    def reload! = (require_client!; _client.invitation(id))

    # @return [Boolean]
    def accepted? = !!accepted
  end
end
