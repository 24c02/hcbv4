# frozen_string_literal: true

module HCBV4
  # A comment on a transaction.
  Comment = Data.define(:id, :created_at, :content, :file, :admin_only, :user) do
    # @param hash [Hash] API response
    # @return [Comment]
    def self.from_hash(hash)
      new(
        id: hash["id"], created_at: hash["created_at"], content: hash["content"],
        file: hash["file"], admin_only: hash["admin_only"],
        user: hash["user"] ? User.from_hash(hash["user"]) : nil
      )
    end

    # @return [Boolean] true if only visible to HCB emails
    def admin_only? = !!admin_only
  end
end
