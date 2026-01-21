# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Seeding brands..."

# Retail brands
retail_brands = [
  { name: "Amazon", category: "retail", logo_url: "https://logo.clearbit.com/amazon.com", website_url: "https://www.amazon.com" },
  { name: "Target", category: "retail", logo_url: "https://logo.clearbit.com/target.com", website_url: "https://www.target.com" },
  { name: "Walmart", category: "retail", logo_url: "https://logo.clearbit.com/walmart.com", website_url: "https://www.walmart.com" },
  { name: "Best Buy", category: "retail", logo_url: "https://logo.clearbit.com/bestbuy.com", website_url: "https://www.bestbuy.com" },
  { name: "Macy's", category: "retail", logo_url: "https://logo.clearbit.com/macys.com", website_url: "https://www.macys.com" },
  { name: "Nordstrom", category: "retail", logo_url: "https://logo.clearbit.com/nordstrom.com", website_url: "https://www.nordstrom.com" },
  { name: "Nike", category: "retail", logo_url: "https://logo.clearbit.com/nike.com", website_url: "https://www.nike.com" },
  { name: "Sephora", category: "retail", logo_url: "https://logo.clearbit.com/sephora.com", website_url: "https://www.sephora.com" },
  { name: "Home Depot", category: "retail", logo_url: "https://logo.clearbit.com/homedepot.com", website_url: "https://www.homedepot.com" },
  { name: "Lowe's", category: "retail", logo_url: "https://logo.clearbit.com/lowes.com", website_url: "https://www.lowes.com" },
  { name: "Costco", category: "retail", logo_url: "https://logo.clearbit.com/costco.com", website_url: "https://www.costco.com" },
  { name: "Apple", category: "retail", logo_url: "https://logo.clearbit.com/apple.com", website_url: "https://www.apple.com" },
  { name: "Bed Bath & Beyond", category: "retail", logo_url: "https://logo.clearbit.com/bedbathandbeyond.com", website_url: "https://www.bedbathandbeyond.com" },
  { name: "Gap", category: "retail", logo_url: "https://logo.clearbit.com/gap.com", website_url: "https://www.gap.com" },
  { name: "Old Navy", category: "retail", logo_url: "https://logo.clearbit.com/oldnavy.com", website_url: "https://www.oldnavy.com" },
]

# Food brands
food_brands = [
  { name: "Starbucks", category: "food", logo_url: "https://logo.clearbit.com/starbucks.com", website_url: "https://www.starbucks.com" },
  { name: "Chipotle", category: "food", logo_url: "https://logo.clearbit.com/chipotle.com", website_url: "https://www.chipotle.com" },
  { name: "Panera Bread", category: "food", logo_url: "https://logo.clearbit.com/panerabread.com", website_url: "https://www.panerabread.com" },
  { name: "Chick-fil-A", category: "food", logo_url: "https://logo.clearbit.com/chick-fil-a.com", website_url: "https://www.chick-fil-a.com" },
  { name: "Dunkin'", category: "food", logo_url: "https://logo.clearbit.com/dunkindonuts.com", website_url: "https://www.dunkindonuts.com" },
  { name: "Subway", category: "food", logo_url: "https://logo.clearbit.com/subway.com", website_url: "https://www.subway.com" },
  { name: "Olive Garden", category: "food", logo_url: "https://logo.clearbit.com/olivegarden.com", website_url: "https://www.olivegarden.com" },
  { name: "Applebee's", category: "food", logo_url: "https://logo.clearbit.com/applebees.com", website_url: "https://www.applebees.com" },
  { name: "Buffalo Wild Wings", category: "food", logo_url: "https://logo.clearbit.com/buffalowildwings.com", website_url: "https://www.buffalowildwings.com" },
  { name: "Domino's", category: "food", logo_url: "https://logo.clearbit.com/dominos.com", website_url: "https://www.dominos.com" },
  { name: "McDonald's", category: "food", logo_url: "https://logo.clearbit.com/mcdonalds.com", website_url: "https://www.mcdonalds.com" },
  { name: "Taco Bell", category: "food", logo_url: "https://logo.clearbit.com/tacobell.com", website_url: "https://www.tacobell.com" },
  { name: "Wendy's", category: "food", logo_url: "https://logo.clearbit.com/wendys.com", website_url: "https://www.wendys.com" },
  { name: "DoorDash", category: "food", logo_url: "https://logo.clearbit.com/doordash.com", website_url: "https://www.doordash.com" },
  { name: "Uber Eats", category: "food", logo_url: "https://logo.clearbit.com/ubereats.com", website_url: "https://www.ubereats.com" },
]

# Entertainment brands
entertainment_brands = [
  { name: "Netflix", category: "entertainment", logo_url: "https://logo.clearbit.com/netflix.com", website_url: "https://www.netflix.com" },
  { name: "Spotify", category: "entertainment", logo_url: "https://logo.clearbit.com/spotify.com", website_url: "https://www.spotify.com" },
  { name: "Disney+", category: "entertainment", logo_url: "https://logo.clearbit.com/disneyplus.com", website_url: "https://www.disneyplus.com" },
  { name: "Hulu", category: "entertainment", logo_url: "https://logo.clearbit.com/hulu.com", website_url: "https://www.hulu.com" },
  { name: "PlayStation Store", category: "entertainment", logo_url: "https://logo.clearbit.com/playstation.com", website_url: "https://store.playstation.com" },
  { name: "Xbox", category: "entertainment", logo_url: "https://logo.clearbit.com/xbox.com", website_url: "https://www.xbox.com" },
  { name: "Nintendo eShop", category: "entertainment", logo_url: "https://logo.clearbit.com/nintendo.com", website_url: "https://www.nintendo.com" },
  { name: "Steam", category: "entertainment", logo_url: "https://logo.clearbit.com/steampowered.com", website_url: "https://store.steampowered.com" },
  { name: "Google Play", category: "entertainment", logo_url: "https://logo.clearbit.com/play.google.com", website_url: "https://play.google.com" },
  { name: "iTunes", category: "entertainment", logo_url: "https://logo.clearbit.com/apple.com", website_url: "https://www.apple.com/itunes" },
  { name: "AMC Theatres", category: "entertainment", logo_url: "https://logo.clearbit.com/amctheatres.com", website_url: "https://www.amctheatres.com" },
  { name: "Regal Cinemas", category: "entertainment", logo_url: "https://logo.clearbit.com/regmovies.com", website_url: "https://www.regmovies.com" },
]

# Travel brands
travel_brands = [
  { name: "Uber", category: "travel", logo_url: "https://logo.clearbit.com/uber.com", website_url: "https://www.uber.com" },
  { name: "Lyft", category: "travel", logo_url: "https://logo.clearbit.com/lyft.com", website_url: "https://www.lyft.com" },
  { name: "Airbnb", category: "travel", logo_url: "https://logo.clearbit.com/airbnb.com", website_url: "https://www.airbnb.com" },
  { name: "Delta Airlines", category: "travel", logo_url: "https://logo.clearbit.com/delta.com", website_url: "https://www.delta.com" },
  { name: "Southwest Airlines", category: "travel", logo_url: "https://logo.clearbit.com/southwest.com", website_url: "https://www.southwest.com" },
  { name: "Marriott", category: "travel", logo_url: "https://logo.clearbit.com/marriott.com", website_url: "https://www.marriott.com" },
  { name: "Hilton", category: "travel", logo_url: "https://logo.clearbit.com/hilton.com", website_url: "https://www.hilton.com" },
]

# Gas brands
gas_brands = [
  { name: "Shell", category: "gas", logo_url: "https://logo.clearbit.com/shell.com", website_url: "https://www.shell.com" },
  { name: "ExxonMobil", category: "gas", logo_url: "https://logo.clearbit.com/exxonmobil.com", website_url: "https://www.exxon.com" },
  { name: "Chevron", category: "gas", logo_url: "https://logo.clearbit.com/chevron.com", website_url: "https://www.chevron.com" },
  { name: "BP", category: "gas", logo_url: "https://logo.clearbit.com/bp.com", website_url: "https://www.bp.com" },
  { name: "Sunoco", category: "gas", logo_url: "https://logo.clearbit.com/sunoco.com", website_url: "https://www.sunoco.com" },
]

# Grocery brands
grocery_brands = [
  { name: "Whole Foods", category: "grocery", logo_url: "https://logo.clearbit.com/wholefoodsmarket.com", website_url: "https://www.wholefoodsmarket.com" },
  { name: "Kroger", category: "grocery", logo_url: "https://logo.clearbit.com/kroger.com", website_url: "https://www.kroger.com" },
  { name: "Safeway", category: "grocery", logo_url: "https://logo.clearbit.com/safeway.com", website_url: "https://www.safeway.com" },
  { name: "Trader Joe's", category: "grocery", logo_url: "https://logo.clearbit.com/traderjoes.com", website_url: "https://www.traderjoes.com" },
  { name: "Albertsons", category: "grocery", logo_url: "https://logo.clearbit.com/albertsons.com", website_url: "https://www.albertsons.com" },
  { name: "Publix", category: "grocery", logo_url: "https://logo.clearbit.com/publix.com", website_url: "https://www.publix.com" },
]

# Other brands
other_brands = [
  { name: "Visa Gift Card", category: "other", logo_url: "https://logo.clearbit.com/visa.com", website_url: "https://www.visa.com" },
  { name: "Mastercard Gift Card", category: "other", logo_url: "https://logo.clearbit.com/mastercard.com", website_url: "https://www.mastercard.com" },
  { name: "American Express Gift Card", category: "other", logo_url: "https://logo.clearbit.com/americanexpress.com", website_url: "https://www.americanexpress.com" },
]

all_brands = retail_brands + food_brands + entertainment_brands + travel_brands + gas_brands + grocery_brands + other_brands

all_brands.each do |brand_attrs|
  Brand.find_or_create_by!(name: brand_attrs[:name]) do |brand|
    brand.category = brand_attrs[:category]
    brand.logo_url = brand_attrs[:logo_url]
    brand.website_url = brand_attrs[:website_url]
    brand.active = true
  end
end

puts "Created #{Brand.count} brands"

# Create a demo user with some gift cards (only in development)
if Rails.env.development?
  puts "Creating demo user and gift cards..."

  demo_user = User.find_or_create_by!(email: "demo@cardly.com") do |user|
    user.password = "password123"
    user.password_confirmation = "password123"
    user.name = "Demo User"
  end

  # Create some gift cards for the demo user
  demo_cards = [
    { brand: "Amazon", original_value: 100.00, balance: 67.50, card_number: "6035123456789012", pin: "1234", expiration_date: 1.year.from_now, acquired_from: "gift" },
    { brand: "Starbucks", original_value: 50.00, balance: 23.45, card_number: "6141789012345678", pin: "5678", expiration_date: nil, acquired_from: "purchased" },
    { brand: "Target", original_value: 75.00, balance: 75.00, card_number: "4901234567890123", pin: "9012", expiration_date: 6.months.from_now, acquired_from: "gift" },
    { brand: "Netflix", original_value: 30.00, balance: 0.00, card_number: "NF123456789", pin: nil, expiration_date: nil, acquired_from: "purchased" },
    { brand: "Chipotle", original_value: 25.00, balance: 12.80, card_number: "7891234567890", pin: "3456", expiration_date: 2.years.from_now, acquired_from: "bought_on_cardly" },
    { brand: "Best Buy", original_value: 200.00, balance: 143.22, card_number: "BB98765432101234", pin: "7890", expiration_date: nil, acquired_from: "gift" },
    { brand: "Uber", original_value: 50.00, balance: 35.00, card_number: nil, pin: nil, expiration_date: nil, acquired_from: "traded" },
    { brand: "Apple", original_value: 100.00, balance: 100.00, card_number: "X1234567890ABCDEF", pin: nil, expiration_date: nil, acquired_from: "gift" },
    { brand: "Home Depot", original_value: 150.00, balance: 89.50, card_number: "HD567890123456", pin: "2468", expiration_date: 30.days.from_now, acquired_from: "purchased" },
    { brand: "Spotify", original_value: 60.00, balance: 0.00, card_number: "SP9876543210", pin: nil, expiration_date: nil, acquired_from: "purchased" },
  ]

  demo_cards.each do |card_attrs|
    brand = Brand.find_by(name: card_attrs[:brand])
    next unless brand

    GiftCard.find_or_create_by!(user: demo_user, brand: brand, card_number: card_attrs[:card_number]) do |card|
      card.original_value = card_attrs[:original_value]
      card.balance = card_attrs[:balance]
      card.pin = card_attrs[:pin]
      card.expiration_date = card_attrs[:expiration_date]
      card.acquired_from = card_attrs[:acquired_from]
      card.acquired_date = rand(1..180).days.ago.to_date
      card.status = card.balance.zero? ? "used" : "active"
    end
  end

  puts "Created #{demo_user.gift_cards.count} gift cards for demo user"

  # Create a sample listing
  active_card = demo_user.gift_cards.where("balance > 50").where(status: "active").first
  if active_card && !active_card.listing
    Listing.create!(
      gift_card: active_card,
      user: demo_user,
      listing_type: "sale",
      asking_price: (active_card.balance * 0.9).round(2),
      description: "Great gift card, barely used! Selling at 10% off face value."
    )
    active_card.update!(status: "listed")
    puts "Created sample listing"
  end
end

puts "Seeding complete!"
