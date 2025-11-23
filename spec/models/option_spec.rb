require "rails_helper"

RSpec.describe Option, type: :model do
  let(:catalog) { create(:catalog) }
  let(:section) { create(:section, catalog: catalog) }
  let(:item) { create(:item, section: section) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:item_id) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_numericality_of(:price).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_presence_of(:currency) }
    it { is_expected.to validate_presence_of(:display_order) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:item) }
  end

  describe "valid option" do
    it "is valid with valid attributes" do
      option = Option.new(
        item: item,
        name: "Test Option",
        price: 2.50,
        currency: "USD",
        display_order: 0
      )
      expect(option).to be_valid
    end

    it "is valid with zero price" do
      option = Option.new(
        item: item,
        name: "Free Option",
        price: 0.00,
        currency: "USD",
        display_order: 0
      )
      expect(option).to be_valid
    end
  end

  describe "associations behavior" do
    it "belongs to item" do
      option = create(:option, item: item)
      expect(option.item).to eq(item)
    end
  end

  describe "scopes" do
    describe ".active" do
      let!(:active_option) { create(:option, item: item, active: true) }
      let!(:inactive_option) { create(:option, item: item, active: false) }

      it "returns only active options" do
        expect(Option.active).to include(active_option)
        expect(Option.active).not_to include(inactive_option)
      end
    end
  end
end
