# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Seed data based on Atlas Kitchen API structure
# Reference: https://docs.atlas.kitchen/admin-api-menu-details

# Create the main catalog (menu)
catalog = Catalog.find_or_create_by!(identifier: "atlas-kitchen-2024") do |c|
  c.name = "2024 Menu"
  c.start_date = Date.parse("2024-01-01")
  c.end_date = Date.parse("2024-12-31")
  c.active = true
end

# Create Recommendations section (root section)
recommendations_section = Section.find_or_create_by!(identifier: "2024-recommendations") do |s|
  s.catalog = catalog
  s.name = "Recommendations"
  s.description = "Discover our recommendations, celebrated for their exceptional flavor and quality."
  s.display_order = 0
  s.active = true
end

# Create Chef's Recommendation sub-section
chef_recommendation_subsection = Section.find_or_create_by!(identifier: "2024-chef-recommendation") do |s|
  s.catalog = catalog
  s.parent = recommendations_section
  s.name = "Chef's Recommendation"
  s.description = "Discover Chef Luca Moretti's top picks, featuring extraordinary flavors and craftsmanship."
  s.image_url = "https://storage.io/7shdahd81hdhsa"
  s.display_order = 0
  s.active = true
end

# Create Truffle-Infused Mushroom Risotto item in Chef's Recommendation
Item.find_or_create_by!(sku: "truffle-infused-mushroom-risotto") do |i|
  i.section = chef_recommendation_subsection
  i.name = "Truffle-Infused Mushroom Risotto"
  i.description = "Creamy risotto with truffle oil, wild mushrooms, and Parmesan. Pure indulgence."
  i.price = 20.00  # 2000 cents = $20.00
  i.currency = "SGD"
  i.display_order = 0
  i.image_url = "https://storage.io/dasjjkdhfkjd938"
  i.active = true
end

# Create Customer's Recommendation sub-section
customer_recommendation_subsection = Section.find_or_create_by!(identifier: "2024-customer-recommendation") do |s|
  s.catalog = catalog
  s.parent = recommendations_section
  s.name = "Customer's Recommendation"
  s.description = "Try our customer favorites, beloved for their outstanding flavor and quality."
  s.image_url = "https://storage.io/7shdahd81hdhsa"
  s.display_order = 1
  s.active = true
end

# Create Spicy Lemon-Garlic Chicken Skewers item (configurable product)
spicy_skewers = Item.find_or_create_by!(sku: "spicy-lemon-garlic-skewers") do |i|
  i.section = customer_recommendation_subsection
  i.name = "Spicy Lemon-Garlic Chicken Skewers"
  i.description = "Tender meat skewers marinated in zesty lemon and spicy garlic."
  i.price = 10.00  # 1000 cents = $10.00
  i.currency = "SGD"
  i.display_order = 0
  i.image_url = "https://storage.io/abcd1234efgh5678"
  i.active = true
end

# Create options (modifiers) for the Spicy Lemon-Garlic Skewers
# These represent the protein choices from the modifier group
Option.find_or_create_by!(item: spicy_skewers, name: "Chicken") do |o|
  o.description = nil
  o.price = 0.00
  o.currency = "SGD"
  o.display_order = 0
  o.active = true
end

Option.find_or_create_by!(item: spicy_skewers, name: "Pork") do |o|
  o.description = nil
  o.price = 0.00
  o.currency = "SGD"
  o.display_order = 1
  o.active = true
end

Option.find_or_create_by!(item: spicy_skewers, name: "Beef") do |o|
  o.description = nil
  o.price = 3.00  # 300 cents = $3.00
  o.currency = "SGD"
  o.display_order = 2
  o.active = true
end

# Create Desserts section (root section)
desserts_section = Section.find_or_create_by!(identifier: "2024-desserts") do |s|
  s.catalog = catalog
  s.name = "Desserts"
  s.description = "Indulge in our delectable desserts, crafted for ultimate sweet satisfaction."
  s.display_order = 1
  s.active = true
end

# Create Classic Chocolate Lava Cake item
Item.find_or_create_by!(sku: "classic-chocolate-lava-cake") do |i|
  i.section = desserts_section
  i.name = "Classic Chocolate Lava Cake"
  i.description = "Decadent molten chocolate cake with a gooey, rich center."
  i.price = 10.00  # 1000 cents = $10.00
  i.currency = "SGD"
  i.display_order = 0
  i.image_url = "https://storage.io/wxyz5678ijkl9101"
  i.active = true
end

puts "✅ Seed data created successfully!"
puts "   - Catalog: #{catalog.name} (#{catalog.identifier})"
puts "   - Sections: #{Section.where(catalog: catalog).count}"
puts "   - Items: #{Item.joins(section: :catalog).where(catalogs: { id: catalog.id }).count}"
puts "   - Options: #{Option.joins(item: { section: :catalog }).where(catalogs: { id: catalog.id }).count}"
