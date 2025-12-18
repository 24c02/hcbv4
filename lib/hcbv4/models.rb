# frozen_string_literal: true

# Modules first
require_relative "models/resource"
require_relative "models/transaction_type"

# Base classes (no dependencies)
require_relative "models/user"
require_relative "models/organization_user"
require_relative "models/tag"
require_relative "models/merchant"
require_relative "models/card_design"
require_relative "models/donation"

# Transaction detail base and subtypes
require_relative "models/base_transaction_detail"
require_relative "models/check"
require_relative "models/invoice_transaction"
require_relative "models/donation_transaction"
require_relative "models/expense_payout"

# Models with Organization/User dependencies
require_relative "models/organization"
require_relative "models/transfer"
require_relative "models/ach_transfer"
require_relative "models/stripe_card"
require_relative "models/card_charge"

# Models with complex dependencies
require_relative "models/card_grant"
require_relative "models/transaction"
require_relative "models/transaction_list"
require_relative "models/invoice"
require_relative "models/sponsor"
require_relative "models/receipt"
require_relative "models/comment"
require_relative "models/invitation"
