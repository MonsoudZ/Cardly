require "test_helper"

class BrandTest < ActiveSupport::TestCase
  test "valid brand" do
    brand = brands(:amazon)
    assert brand.valid?
  end

  test "requires name" do
    brand = Brand.new(category: "retail")
    assert_not brand.valid?
    assert_includes brand.errors[:name], "can't be blank"
  end

  test "name must be unique" do
    brand = Brand.new(name: "Amazon", category: "retail")
    assert_not brand.valid?
    assert_includes brand.errors[:name], "has already been taken"
  end

  test "category must be valid" do
    brand = brands(:amazon)
    brand.category = "invalid"
    assert_not brand.valid?
    assert_includes brand.errors[:category], "is not included in the list"
  end

  test "active scope returns only active brands" do
    active_brands = Brand.active
    assert active_brands.include?(brands(:amazon))
    assert_not active_brands.include?(brands(:inactive_brand))
  end

  test "by_category scope filters by category" do
    retail_brands = Brand.by_category("retail")
    assert retail_brands.include?(brands(:amazon))
    assert retail_brands.include?(brands(:target))
    assert_not retail_brands.include?(brands(:starbucks))
  end

  test "display_logo returns logo_url if present" do
    brand = brands(:amazon)
    assert_equal brand.logo_url, brand.display_logo
  end

  test "display_logo returns placeholder if logo_url is blank" do
    brand = Brand.new(name: "Test Brand")
    assert_includes brand.display_logo, "placehold.co"
    assert_includes brand.display_logo, "TES"
  end
end
