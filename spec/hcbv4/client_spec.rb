# frozen_string_literal: true

RSpec.describe HCBV4::Client do
  let(:access_token) { "test_access_token" }
  let(:oauth_token) { instance_double(OAuth2::AccessToken, token: access_token, expired?: false) }
  let(:client) { described_class.new(oauth_token: oauth_token) }
  let(:base_url) { "https://hcb.hackclub.com/api/v4" }

  describe ".from_credentials" do
    it "creates a client with OAuth2 credentials" do
      client = described_class.from_credentials(
        client_id: "client_id",
        client_secret: "client_secret",
        access_token: "access_token",
        refresh_token: "refresh_token",
        expires_at: Time.now.to_i + 3600
      )

      expect(client).to be_a(described_class)
      expect(client.oauth_token).to be_a(OAuth2::AccessToken)
    end
  end

  describe "#me" do
    it "returns the current user" do
      stub_request(:get, "#{base_url}/user")
        .to_return(
          status: 200,
          body: { id: "usr_123", name: "Test User", email: "test@example.com" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      user = client.me

      expect(user).to be_a(HCBV4::User)
      expect(user.id).to eq("usr_123")
      expect(user.name).to eq("Test User")
    end
  end

  describe "#organizations" do
    it "returns a list of organizations" do
      stub_request(:get, "#{base_url}/user/organizations")
        .to_return(
          status: 200,
          body: [
            { id: "evt_123", name: "Test Org", slug: "test-org" },
            { id: "evt_456", name: "Another Org", slug: "another-org" }
          ].to_json,
          headers: { "Content-Type" => "application/json" }
        )

      orgs = client.organizations

      expect(orgs).to be_an(Array)
      expect(orgs.length).to eq(2)
      expect(orgs.first).to be_a(HCBV4::Organization)
      expect(orgs.first.name).to eq("Test Org")
    end
  end

  describe "#transactions" do
    it "returns a transaction list with pagination" do
      stub_request(:get, "#{base_url}/organizations/test-org/transactions")
        .to_return(
          status: 200,
          body: {
            data: [
              { id: "txn_123", amount_cents: -1000, memo: "Coffee", date: "2024-01-15" }
            ],
            total_count: 100,
            has_more: true
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = client.transactions("test-org")

      expect(result).to be_a(HCBV4::TransactionList)
      expect(result.data.first).to be_a(HCBV4::Transaction)
      expect(result.total_count).to eq(100)
      expect(result.has_more).to be(true)
    end
  end

  describe "#create_card_grant" do
    it "creates a card grant" do
      stub_request(:post, "#{base_url}/organizations/evt_123/card_grants")
        .with(body: { amount_cents: 5000, email: "user@example.com" }.to_json)
        .to_return(
          status: 201,
          body: { id: "cg_123", amount_cents: 5000, email: "user@example.com", status: "pending" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      grant = client.create_card_grant(event_id: "evt_123", amount_cents: 5000, email: "user@example.com")

      expect(grant).to be_a(HCBV4::CardGrant)
      expect(grant.amount_cents).to eq(5000)
    end
  end

  describe "error handling" do
    it "raises UnauthorizedError on 401" do
      stub_request(:get, "#{base_url}/user")
        .to_return(status: 401, body: { error: "unauthorized",
                                        messages: ["Invalid token"] }.to_json, headers: { "Content-Type" => "application/json" })

      expect { client.me }.to raise_error(HCBV4::UnauthorizedError)
    end

    it "raises NotFoundError on 404" do
      stub_request(:get, "#{base_url}/organizations/nonexistent")
        .to_return(status: 404, body: { error: "not_found",
                                        messages: ["Event not found"] }.to_json, headers: { "Content-Type" => "application/json" })

      expect { client.organization("nonexistent") }.to raise_error(HCBV4::NotFoundError)
    end

    it "raises InvalidOperationError for invalid_operation errors" do
      stub_request(:post, "#{base_url}/card_grants/cg_123/cancel")
        .to_return(status: 400, body: { error: "invalid_operation",
                                        messages: ["Cannot cancel"] }.to_json, headers: { "Content-Type" => "application/json" })

      expect { client.cancel_card_grant("cg_123") }.to raise_error(HCBV4::InvalidOperationError)
    end

    it "raises RateLimitError on 429" do
      stub_request(:get, "#{base_url}/user")
        .to_return(status: 429, body: { error: "rate_limited",
                                        messages: ["Too many requests"] }.to_json, headers: { "Content-Type" => "application/json" })

      expect { client.me }.to raise_error(HCBV4::RateLimitError)
    end
  end

  describe "token refresh" do
    it "refreshes expired tokens automatically" do
      expired_token = instance_double(OAuth2::AccessToken, token: "old_token", expired?: true)
      new_token = instance_double(OAuth2::AccessToken, token: "new_token", expired?: false)
      allow(expired_token).to receive(:refresh!).and_return(new_token)

      client = described_class.new(oauth_token: expired_token)

      stub_request(:get, "#{base_url}/user")
        .to_return(status: 200, body: { id: "usr_123" }.to_json, headers: { "Content-Type" => "application/json" })

      client.me

      expect(expired_token).to have_received(:refresh!)
      expect(client.oauth_token).to eq(new_token)
    end
  end
end
