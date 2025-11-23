require "rails_helper"

RSpec.describe Item, type: :model do
  let(:catalog) { create(:catalog) }
  let(:section) { create(:section, catalog: catalog) }
  subject { build(:item, section: section) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:sku) }
    it { is_expected.to validate_uniqueness_of(:sku) }
    it { is_expected.to validate_presence_of(:section_id) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:price) }
    it { is_expected.to validate_numericality_of(:price).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_presence_of(:currency) }
    it { is_expected.to validate_presence_of(:display_order) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:section) }
    it { is_expected.to have_many(:options).dependent(:destroy) }
  end

  describe "valid item" do
    it "is valid with valid attributes" do
      item = Item.new(
        sku: "test-item",
        section: section,
        name: "Test Item",
        price: 10.50,
        currency: "USD",
        display_order: 0
      )
      expect(item).to be_valid
    end
  end

  describe "associations behavior" do
    it "belongs to section" do
      item = create(:item, section: section)
      expect(item.section).to eq(section)
    end

    it "has options" do
      item = create(:item, section: section)
      option1 = create(:option, item: item, display_order: 0)
      option2 = create(:option, item: item, display_order: 1)

      expect(item.options.count).to eq(2)
      expect(item.options).to include(option1, option2)
    end
  end

  describe "scopes" do
    describe ".active" do
      let!(:active_item) { create(:item, section: section, active: true) }
      let!(:inactive_item) { create(:item, section: section, active: false) }

      it "returns only active items" do
        expect(Item.active).to include(active_item)
        expect(Item.active).not_to include(inactive_item)
      end
    end
  end
end
