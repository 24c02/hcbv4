# frozen_string_literal: true

RSpec.describe "Models" do
  describe HCBV4::User do
    it "parses from hash" do
      hash = {
        "id" => "usr_123",
        "name" => "Stagey McStageFace",
        "email" => "admin@bank.engineering",
        "admin" => true,
        "shipping_address" => {
          "address_line1" => "8605 Santa Monica Blvd",
          "city" => "West Hollywood",
          "state" => "CA",
          "postal_code" => "90069 ",
          "country" => "US"
        }
      }
      user = described_class.from_hash(hash)

      expect(user.id).to eq("usr_123")
      expect(user.name).to eq("Stagey McStageFace")
      expect(user.admin?).to be(true)
      expect(user.shipping_address).to be_a(HCBV4::ShippingAddress)
      expect(user.shipping_address.city).to eq("West Hollywood")
    end

    it "handles missing shipping_address" do
      user = described_class.from_hash({ "id" => "usr_123" })
      expect(user.shipping_address).to be_nil
    end
  end

  describe HCBV4::OrganizationUser do
    it "inherits from User and adds role" do
      org_user = described_class.from_hash({
        "id" => "usr_123",
        "name" => "Org Member",
        "role" => "manager",
        "joined_at" => "2024-01-01T00:00:00Z"
      })

      expect(org_user).to be_a(HCBV4::User)
      expect(org_user.role).to eq("manager")
      expect(org_user.joined_at).to eq("2024-01-01T00:00:00Z")
    end
  end

  describe HCBV4::Organization do
    it "parses from hash with users" do
      org = described_class.from_hash({
        "id" => "evt_123",
        "name" => "Test Org",
        "slug" => "test-org",
        "balance_cents" => 100_000,
        "users" => [
          { "id" => "usr_1", "name" => "User 1", "role" => "owner" }
        ]
      })

      expect(org.id).to eq("evt_123")
      expect(org.name).to eq("Test Org")
      expect(org.users.first).to be_a(HCBV4::OrganizationUser)
    end
  end

  describe HCBV4::Transaction do
    it "parses transaction with card_charge" do
      tx = described_class.from_hash({
        "id" => "txn_123",
        "amount_cents" => -1500,
        "memo" => "Coffee Shop",
        "date" => "2024-01-15",
        "pending" => false,
        "card_charge" => {
          "merchant" => { "name" => "Starbucks", "smart_name" => "Starbucks Coffee" },
          "charge_method" => "contactless",
          "spent_at" => "2024-01-15T10:30:00Z"
        }
      })

      expect(tx.type).to eq(:card_charge)
      expect(tx.card_charge).to be_a(HCBV4::CardCharge)
      expect(tx.card_charge.merchant.name).to eq("Starbucks")
    end

    it "parses transaction with donation" do
      tx = described_class.from_hash({
        "id" => "txn_456",
        "amount_cents" => 5000,
        "donation" => {
          "recurring" => true,
          "donor" => { "name" => "John Doe", "email" => "john@example.com" },
          "message" => "Keep up the good work!"
        }
      })

      expect(tx.type).to eq(:donation)
      expect(tx.donation.recurring?).to be(true)
      expect(tx.donation.donor.name).to eq("John Doe")
    end

    it "parses transaction with transfer" do
      tx = described_class.from_hash({
        "id" => "txn_789",
        "amount_cents" => 10_000,
        "transfer" => {
          "id" => "dis_123",
          "memo" => "Grant funds",
          "from" => { "id" => "evt_1", "name" => "Source Org" },
          "to" => { "id" => "evt_2", "name" => "Dest Org" }
        }
      })

      expect(tx.type).to eq(:transfer)
      expect(tx.transfer.from).to be_a(HCBV4::Organization)
    end
  end

  describe HCBV4::Check do
    it "parses check with all fields" do
      check = described_class.from_hash({
        "id" => "chk_123",
        "status" => "deposited",
        "check_number" => "1001",
        "recipient_name" => "John Doe",
        "address_line1" => "123 Main St",
        "address_city" => "Boston",
        "address_state" => "MA",
        "address_zip" => "02101",
        "payment_for" => "Services rendered",
        "sender" => { "id" => "usr_123", "name" => "Jane" }
      })

      expect(check.check_number).to eq("1001")
      expect(check.address_city).to eq("Boston")
      expect(check.sender).to be_a(HCBV4::User)
    end
  end

  describe HCBV4::CheckDeposit do
    it "parses check deposit with images" do
      deposit = described_class.from_hash({
        "id" => "dep_123",
        "status" => "submitted",
        "front_url" => "https://example.com/front.jpg",
        "back_url" => "https://example.com/back.jpg",
        "submitter" => { "id" => "usr_123" }
      })

      expect(deposit.front_url).to eq("https://example.com/front.jpg")
      expect(deposit.submitter).to be_a(HCBV4::User)
    end
  end

  describe HCBV4::StripeCard do
    it "parses with personalization and shipping" do
      card = described_class.from_hash({
        "id" => "card_123",
        "type" => "physical",
        "status" => "active",
        "last4" => "4242",
        "personalization" => { "color" => "black", "logo_url" => "https://example.com/logo.png" },
        "shipping" => {
          "status" => "delivered",
          "eta" => "2024-01-20",
          "address" => { "line1" => "123 Main St", "city" => "SF", "state" => "CA" }
        }
      })

      expect(card.physical?).to be(true)
      expect(card.personalization.color).to eq("black")
      expect(card.shipping.status).to eq("delivered")
      expect(card.shipping.address.city).to eq("SF")
    end

    it "identifies virtual cards" do
      card = described_class.from_hash({ "id" => "card_123", "type" => "virtual" })
      expect(card.virtual?).to be(true)
      expect(card.physical?).to be(false)
    end
  end

  describe HCBV4::CardGrant do
    it "parses with disbursements" do
      grant = described_class.from_hash({
        "id" => "cg_123",
        "amount_cents" => 10_000,
        "balance_cents" => 5000,
        "status" => "active",
        "disbursements" => [
          { "id" => "dis_1", "amount_cents" => 5000 }
        ]
      })

      expect(grant.disbursements.first).to be_a(HCBV4::Transfer)
    end
  end

  describe HCBV4::DonationTransaction do
    it "parses with attribution" do
      donation = described_class.from_hash({
        "recurring" => false,
        "refunded" => false,
        "donor" => { "name" => "Anonymous" },
        "attribution" => {
          "utm_source" => "twitter",
          "utm_campaign" => "fundraiser"
        }
      })

      expect(donation.recurring?).to be(false)
      expect(donation.attribution.utm_source).to eq("twitter")
    end
  end

  describe HCBV4::InvoiceTransaction do
    it "parses with sponsor" do
      invoice = described_class.from_hash({
        "id" => "inv_123",
        "amount_cents" => 50_000,
        "due_date" => "2024-02-01",
        "sponsor" => { "id" => "sp_123", "name" => "Acme Corp", "email" => "billing@acme.com" }
      })

      expect(invoice.sponsor.name).to eq("Acme Corp")
    end
  end

  describe HCBV4::ExpensePayout do
    it "includes report_id" do
      payout = described_class.from_hash({ "id" => "ep_123", "report_id" => "rpt_456" })
      expect(payout.report_id).to eq("rpt_456")
    end
  end

  describe HCBV4::TransactionList do
    it "parses paginated response" do
      list = described_class.from_hash({
        "data" => [{ "id" => "txn_1" }, { "id" => "txn_2" }],
        "total_count" => 50,
        "has_more" => true
      })

      expect(list.data.length).to eq(2)
      expect(list.total_count).to eq(50)
      expect(list.has_more).to be(true)
      expect(list.has_more?).to be(true)
    end

    it "is Enumerable" do
      list = described_class.from_hash({
        "data" => [{ "id" => "txn_1" }, { "id" => "txn_2" }],
        "total_count" => 2,
        "has_more" => false
      })

      expect(list).to be_a(Enumerable)
      expect(list.map(&:id)).to eq(["txn_1", "txn_2"])
      expect(list.first.id).to eq("txn_1")
      expect(list.count).to eq(2)
    end

    it "returns nil for next_page when no more pages" do
      list = described_class.from_hash({
        "data" => [{ "id" => "txn_1" }],
        "total_count" => 1,
        "has_more" => false
      })

      expect(list.next_page).to be_nil
    end
  end

  describe "predicate methods" do
    it "User has admin? and auditor?" do
      user = HCBV4::User.from_hash({ "id" => "u1", "admin" => true, "auditor" => false })
      expect(user.admin?).to be(true)
      expect(user.auditor?).to be(false)
    end

    it "Comment has admin_only?" do
      comment = HCBV4::Comment.from_hash({ "id" => "c1", "admin_only" => true })
      expect(comment.admin_only?).to be(true)
    end

    it "Transaction has has_custom_memo?, missing_receipt?, lost_receipt?, pending?, declined?" do
      tx = HCBV4::Transaction.from_hash({
        "id" => "t1", "has_custom_memo" => true, "missing_receipt" => false,
        "lost_receipt" => true, "pending" => false, "declined" => false
      })
      expect(tx.has_custom_memo?).to be(true)
      expect(tx.missing_receipt?).to be(false)
      expect(tx.lost_receipt?).to be(true)
      expect(tx.pending?).to be(false)
      expect(tx.declined?).to be(false)
    end

    it "CardGrant has lock predicates" do
      grant = HCBV4::CardGrant.from_hash({
        "id" => "cg1", "merchant_lock" => true, "category_lock" => false,
        "keyword_lock" => true, "one_time_use" => false, "pre_authorization_required" => true
      })
      expect(grant.merchant_lock?).to be(true)
      expect(grant.category_lock?).to be(false)
      expect(grant.keyword_lock?).to be(true)
      expect(grant.one_time_use?).to be(false)
      expect(grant.pre_authorization_required?).to be(true)
    end

    it "Organization has boolean predicates" do
      org = HCBV4::Organization.from_hash({
        "id" => "o1", "donation_page_available" => true, "playground_mode" => false,
        "playground_mode_meeting_requested" => true, "transparent" => true
      })
      expect(org.donation_page_available?).to be(true)
      expect(org.playground_mode?).to be(false)
      expect(org.playground_mode_meeting_requested?).to be(true)
      expect(org.transparent?).to be(true)
    end

    it "Invitation has accepted?" do
      inv = HCBV4::Invitation.from_hash({ "id" => "i1", "accepted" => true })
      expect(inv.accepted?).to be(true)
    end

    it "CardDesign has unlisted? and common?" do
      design = HCBV4::CardDesign.from_hash({ "id" => 1, "unlisted" => false, "common" => true })
      expect(design.unlisted?).to be(false)
      expect(design.common?).to be(true)
    end

    it "DonationTransaction has recurring? and refunded?" do
      donation = HCBV4::DonationTransaction.from_hash({ "recurring" => true, "refunded" => false })
      expect(donation.recurring?).to be(true)
      expect(donation.refunded?).to be(false)
    end

    it "StripeCard has virtual? and physical?" do
      virtual = HCBV4::StripeCard.from_hash({ "id" => "c1", "type" => "virtual" })
      physical = HCBV4::StripeCard.from_hash({ "id" => "c2", "type" => "physical" })
      expect(virtual.virtual?).to be(true)
      expect(virtual.physical?).to be(false)
      expect(physical.physical?).to be(true)
      expect(physical.virtual?).to be(false)
    end
  end
end
