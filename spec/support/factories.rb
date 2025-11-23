FactoryBot.define do
  factory :catalog do
    identifier { "catalog-#{SecureRandom.hex(4)}" }
    name { "Test Catalog" }
    start_date { Date.today }
    end_date { Date.today + 1.year }
    active { true }
  end

  factory :section do
    association :catalog
    identifier { "section-#{SecureRandom.hex(4)}" }
    name { "Test Section" }
    display_order { 0 }
    active { true }
  end

  factory :item do
    association :section
    sku { "item-#{SecureRandom.hex(4)}" }
    name { "Test Item" }
    price { 10.00 }
    currency { "USD" }
    display_order { 0 }
    active { true }
  end

  factory :option do
    association :item
    name { "Test Option" }
    price { 2.00 }
    currency { "USD" }
    display_order { 0 }
    active { true }
  end
end
