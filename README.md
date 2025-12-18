# hcbv4

an unofficial Ruby client for the [HCB](https://hackclub.com/hcb/) v4 API.

this gem handles OAuth2 token refresh, cursor-based pagination, and wraps API responses in immutable `Data` objects with chainable methods.

## installation

```ruby
gem "hcbv4"
```

requires Ruby 3.2+.

## authentication

the HCB API uses OAuth2 for authentication. you'll need to get an admin to register an OAuth application to get a `client_id` and `client_secret`, then implement the standard OAuth2 authorization code flow to obtain tokens.

### creating a client from credentials

once you have tokens from your OAuth flow:

```ruby
client = HCBV4::Client.from_credentials(
  client_id: ENV["HCB_CLIENT_ID"],
  client_secret: ENV["HCB_CLIENT_SECRET"],
  access_token: "...",
  refresh_token: "...",
  expires_at: 1734567890  # unix timestamp, optional
)
```

the client automatically refreshes expired tokens before each request. after any API call, you can grab the (possibly refreshed) tokens to persist them:

```ruby
token = client.oauth_token
save_to_database(
  access_token: token.token,
  refresh_token: token.refresh_token,
  expires_at: token.expires_at
)
```

### disabling automatic token refresh

if you're managing token refresh yourself, you can disable automatic refresh:

```ruby
client = HCBV4::Client.from_credentials(
  client_id: ENV["HCB_CLIENT_ID"],
  client_secret: ENV["HCB_CLIENT_SECRET"],
  access_token: "...",
  refresh_token: "...",
  auto_token_refresh: false
)
```

the `auto_token_refresh` option defaults to `true`.

### using a pre-built token

if you're managing the `OAuth2::AccessToken` lifecycle yourself:

```ruby
client = HCBV4::Client.new(oauth_token: your_oauth2_token)
```

### custom base URL

you'll probably want to test your integrations far away from real dollars!

```ruby
client = HCBV4::Client.from_credentials(
  # ...credentials...
  base_url: "http://localhost:300"
)
```

## basic usage

```ruby
# get the authenticated user
me = client.me
puts "logged in as #{me.name} (#{me.email})"

# list organizations the user belongs to
orgs = client.organizations(expand: [:balance_cents, :users])
orgs.each do |org|
  puts "#{org.name}: $#{org.balance_cents / 100.0}"
  org.users&.each { |u| puts "  - #{u.name} (#{u.role})" }
end

# fetch a specific organization by ID or slug
org = client.organization("hq", expand: [:balance_cents, :account_number])
puts "balance: $#{org.balance_cents / 100.0}"
puts "account: #{org.routing_number} / #{org.account_number}"
```

## pagination

endpoints that return lists use cursor-based pagination. the gem returns a `TransactionList` that includes pagination state:

```ruby
# fetch the first page
txs = client.transactions("my-org", limit: 50)

# iterate through all pages
loop do
  txs.each do |tx|
    puts "#{tx.date}: #{tx.memo} (#{tx.amount_cents})"
  end
  
  break unless txs.has_more?
  txs = txs.next_page
end
```

the pagination context (filters, expand options, etc.) is preserved across pages, so `next_page` returns consistent results.

## stub resources

sometimes you already have a resource ID and want to call methods on it without fetching the full object first. this is common when handling webhooks or building UIs where the ID comes from user input.

the bang methods create a "stub" resource with just the ID and client attached:

```ruby
# instead of this (makes an API call):
org = client.organization("org_xxx")
org.create_card_grant(amount_cents: 5000, email: "nora@hackclub.com")

# you can do this (no fetch, just action):
org = client.organization!("org_xxx")
org.create_card_grant(amount_cents: 5000, email: "nora@hackclub.com")
```

the stub has `nil` for all attributes except `id`, but action methods work fine because they only need the ID. if you need the actual data later, call `reload!`:

```ruby
org = client.organization!("org_xxx")
org.name  # => nil
org = org.reload!
org.name  # => "My Hackathon"
```

available stub methods: `organization!`, `card_grant!`, `stripe_card!`, `transaction!`, `sponsor!`, `invoice!`, `invitation!`, `receipt!`.

## expand parameters

many endpoints accept an `expand:` parameter to include related data in a single request. without expansion, related fields are `nil`:

```ruby
# without expand - users not included
org = client.organization("my-org")
org.users  # => nil

# with expand - users embedded in response
org = client.organization("my-org", expand: [:users, :balance_cents])
org.users  # => [#<HCBV4::OrganizationUser ...>, ...]
org.balance_cents  # => xxx4500
```

common expand options by endpoint:

| endpoint | expand options |
|----------|----------------|
| `organizations` | `:balance_cents`, `:reporting`, `:account_number`, `:users` |
| `card_grants` | `:user`, `:organization`, `:balance_cents`, `:disbursements` |
| `stripe_cards` | `:user`, `:organization`, `:total_spent_cents`, `:balance_available` |
| `transactions` | `:organization` |

## API reference

### users

```ruby
client.me                        # current authenticated user
client.user("usr_xxx")           # user by ID (admin only)
client.user_by_email("x@y.com")  # user by email (admin only)
```

### organizations

organizations (also called "events" in some API contexts) are the core unit. they hold funds, issue cards, and track transactions.

```ruby
client.organizations(expand: [...])              # all orgs for current user
client.organization("org_or_slug", expand: [...]) # single org by ID or slug

# from an organization object:
org.transactions(limit: 100, type: "card_charge")
org.card_grants(expand: [:balance_cents])
org.stripe_cards(expand: [:total_spent_cents])
org.invoices
org.sponsors
org.followers
org.sub_organizations 

# creating resources under an org:
org.create_card_grant(
  amount_cents: 10000,
  email: "recipient@example.com",
  purpose: "travel expenses",
  merchant_lock: true,
  allowed_merchants: ["uber", "lyft"]
)

org.create_stripe_card(card_type: "virtual")
org.create_stripe_card(
  card_type: "physical",
  design_id: "des_xxx",
  shipping_name: "Jane Doe",
  shipping_address_line1: "xxx Main St",
  shipping_address_city: "San Francisco",
  shipping_address_state: "CA",
  shipping_address_postal_code: "94102",
  shipping_address_country: "US"
)

org.create_sponsor(
  name: "Acme Corp",
  contact_email: "billing@acme.com",
  address_line1: "456 Corporate Blvd",
  address_city: "New York",
  address_state: "NY",
  address_postal_code: "10001"
)

org.create_invoice(
  sponsor_id: "sp_xxx",
  due_date: "2025-12-01",
  item_description: "Gold sponsorship",
  item_amount: 500000  # $5,000 in cents
)

# or, directly on the sponsor:

sponsor.create_invoice(
  due_date: "2025-12-01",
  item_description: "Gold sponsorship",
  item_amount: 500000  # $5,000 in cents
)

org.create_disbursement(
  to_organization_id: "hq",
  amount_cents: 50000,
  name: "i just want them to have some walkin' around money!"
)

org.create_ach_transfer(
  routing_number: "xxx456789",
  account_number: "987654321",
  recipient_name: "Acme Corp",
  amount_money: "150.00",  # string with decimal for some reason? thanks engr, very cool
  payment_for: "widgets. lots of widgets."
)

org.create_invitation(
  email: "newmember@example.com",
  role: "manager",  # or "member"
  enable_spending_controls: true,
  initial_control_allowance_amount: 50000
)

org.create_sub_organization(
  name: "hackathon-travel-team",
  email: "travel-lead@example.com"
)
```

### transactions

transactions represent money moving in or out of an organization. each transaction has a `type` indicating what kind it is, and a corresponding detail object.

```ruby
client.transactions("org_id", limit: 100, type: "card_charge")
client.transaction("txn_xxx", expand: [:organization])
client.missing_receipt_transactions(limit: 50)  # across all orgs

tx = client.transaction("txn_xxx")

# type detection
tx.type     # => :card_charge, :donation, :transfer, :ach_transfer, :check, :invoice, :expense_payout, :check_deposit
tx.details  # => the type-specific object

# for card charges, access merchant info:
if tx.type == :card_charge
  charge = tx.card_charge
  puts "#{charge.merchant.name} - #{charge.merchant.city}, #{charge.merchant.state}"
end

# status checks
tx.pending?
tx.declined?
tx.missing_receipt?
tx.has_custom_memo?

# actions
tx.update!(memo: "team dinner at venue")
tx.reload!

# comments (internal notes on transactions)
tx.comments
tx.add_comment(content: "stop spending all our money on government_licensed_online_casions_online_gambling_us_region_only!", admin_only: true)

# receipts
tx.receipts
tx.add_receipt(file: File.open("receipt.jpg"))

# memo autocomplete based on past transactions
tx.memo_suggestions  # => ["team dinner", "office supplies", ...]
```

### card grants

probably most of the use this gem will see...

```ruby
client.card_grants(expand: [:balance_cents])
client.organization_card_grants("org_id", expand: [:user])
client.card_grant("cg_xxx", expand: [:disbursements])

grant = client.card_grant("cg_xxx")

# fund management
grant.topup!(amount_cents: 5000)    # add $50
grant.withdraw!(amount_cents: 1000) # pull back $10

# lifecycle
grant.activate!  # activate a pending grant
grant.cancel!    # cancel and return remaining funds

# update restrictions
grant.update!(
  purpose: "updated purpose",
  merchant_lock: true,
  allowed_merchants: ["123749823749", "923847293847"] # get these from hack.af/gh/yellow_pages!
)

# status checks
grant.status           # => "pending", "active", "cancelled"
grant.merchant_lock?
grant.category_lock?
grant.one_time_use?
```

### stripe cards

stripe cards are the actual debit cards (virtual or physical) issued to organization members.

```ruby
client.stripe_cards(expand: [:total_spent_cents])
client.organization_stripe_cards("org_xxx")
client.stripe_card("card_xxx")
client.card_designs(event_id: "org_xxx")  # available physical card designs

card = client.stripe_card("card_xxx")

# transactions on this card
card.transactions(limit: 50)
card.transactions(missing_receipts: true)  # only those needing receipts

# card control
card.freeze!
card.unfreeze!
card.cancel!
```

### invoices and sponsors

sponsors are companies/individuals you invoice. invoices track payment status.

```ruby
client.sponsors(event_id: "org_xxx")
client.sponsor("spr_xxx")

sponsor = client.sponsor("spr_xxx")
sponsor.update!(name: "Acme Corporation", contact_email: "new@acme.com")
sponsor.delete!

client.invoices(event_id: "org_xxx")
client.invoice("inv_xxx")

invoice = client.invoice("inv_xxx")
invoice.mark_as_paid!
invoice.void!
invoice.send_reminder!
```

### invitations

pending invitations for the current user to join organizations.

```ruby
client.invitations  # list pending invites

invite = client.invitation("ivt_xxx")
invite.accept!
invite.reject!
```

### receipts

receipts can be attached to transactions or uploaded to a "receipt bin" for later matching.

```ruby
client.receipts(transaction_id: "txn_xxx")

# upload to receipt bin (no transaction yet)
client.create_receipt(file: File.open("receipt.pdf"))

# upload and attach to transaction
client.create_receipt(file: File.open("receipt.pdf"), transaction_id: "txn_xxx")

receipt = client.receipt!("rct_xxx")
receipt.delete!
```

## error handling

all API errors inherit from `HCBV4::APIError` and include structured error information:

```ruby
begin
  client.organization("nonexistent")
rescue HCBV4::NotFoundError => e
  puts e.message     # => "Organization not found"
  puts e.status      # => 404
  puts e.error_code  # => "not_found"
  puts e.messages    # => ["Organization not found"]
rescue HCBV4::RateLimitError => e
  # back off and retry
  sleep 60
  retry
rescue HCBV4::APIError => e
  # catch-all for other API errors
  puts "API error: #{e.message}"
end
```

error hierarchy:

- `HCBV4::APIError` - base class
  - `BadRequestError` (400)
  - `UnauthorizedError` (401) - invalid/expired token
  - `ForbiddenError` (403) - valid token but no permission
  - `NotFoundError` (404)
  - `UnprocessableEntityError` (422) - validation errors
  - `RateLimitError` (429)
  - `ServerError` (5xx)
  - `InvalidOperationError` - operation not allowed in current state
  - `InvalidUserError` - user doesn't exist or can't perform action

## gotchas

### fields that require expand

some fields are always `nil` unless you explicitly expand them. this keeps responses fast when you don't need everything:

```ruby
org = client.organization("my-org")
org.balance_cents   # => nil
org.users           # => nil
org.account_number  # => nil

org = client.organization("my-org", expand: [:balance_cents, :users, :account_number])
org.balance_cents   # => xxx4500
org.users           # => [#<HCBV4::OrganizationUser ...>, ...]
org.account_number  # => "xxx4567890"
```

the same applies to card grants - `disbursements` is only populated with `expand: [:disbursements]`.

### stubs don't have data

stub resources (from `organization!`, `card_grant!`, etc.) have `nil` for all attributes except `id`. if you need to read data, call `reload!` or use the non-bang fetch method:

```ruby
org = client.organization!("org_xxx")
org.name  # => nil (it's a stub!)

org = org.reload!
org.name  # => "My Org"
```

### transactions need organization context for updates

because of wonky v4 routes, when updating a transaction, the gem needs the organization ID. transactions fetched via `client.transactions("org_id")` or with `expand: [:organization]` have this context. stubs don't:

```ruby
# this works - transaction knows its org
tx = client.transactions("my-org").first
tx.update!(memo: "new memo")

# this fails - stub has no org context
tx = client.transaction!("txn_xxx")
tx.update!(memo: "new memo")  # => Error: organization.id is nil
```

## recipes

### token persistence

the client automatically refreshes expired tokens. only persist when the token actually changes:

```ruby
class HCBService
  def self.with(user, &block)
    service = new(user)
    block.call(service.client)
  ensure
    service.persist_if_refreshed!
  end

  def initialize(user)
    @user = user
    @original_token = user.hcb_access_token
  end

  def client
    @client ||= HCBV4::Client.from_credentials(
      client_id: ENV["HCB_CLIENT_ID"],
      client_secret: ENV["HCB_CLIENT_SECRET"],
      access_token: @user.hcb_access_token,
      refresh_token: @user.hcb_refresh_token,
      expires_at: @user.hcb_token_expires_at
    )
  end

  def persist_if_refreshed!
    return unless @client
    token = @client.oauth_token
    return if token.token == @original_token

    @user.update!(
      hcb_access_token: token.token,
      hcb_refresh_token: token.refresh_token,
      hcb_token_expires_at: token.expires_at
    )
  end
end

# usage:
HCBService.with(current_user) do |client|
  client.organizations
end
```

### keep your ledger pretty

when a card grant is created, it generates a disbursement (transfer) from the org to the grant. you might want to label it:

```ruby
org = client.organization!("highseas")

grant = org.create_card_grant(
  amount_cents: 15000,
  email: "nora@hackclub.com",
  purpose: "furthering charitable mission"
)

tx = grant.disbursements.first.transaction!
tx.update!(memo: "[grant] free money for Nora")
```

### raw API access

if you need to call an endpoint not wrapped by the gem:

```ruby
# GET with query params
data = client.get("/some/endpoint", { foo: "bar" })

# POST with JSON body
result = client.post("/some/endpoint", { key: "value" })

# PATCH and DELETE
client.patch("/resource/xxx", { name: "new name" })
client.delete("/resource/xxx")
```

## development:

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## license:

MIT

## disclaimer:

this isn't an official Hack Club or HCB product - it'll probably (definitely) break at some point