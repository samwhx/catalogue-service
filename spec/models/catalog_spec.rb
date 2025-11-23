require "rails_helper"

RSpec.describe Catalog, type: :model do
  subject { build(:catalog) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:identifier) }
    it { is_expected.to validate_uniqueness_of(:identifier) }
    it { is_expected.to validate_presence_of(:name) }
  end

  describe "associations" do
    it { is_expected.to have_many(:sections).dependent(:destroy) }
  end

  describe "scopes" do
    describe ".active" do
      let!(:active_catalog) { create(:catalog, active: true) }
      let!(:inactive_catalog) { create(:catalog, active: false) }

      it "returns only active catalogs" do
        expect(Catalog.active).to include(active_catalog)
        expect(Catalog.active).not_to include(inactive_catalog)
      end
    end
  end

  describe "valid catalog" do
    it "is valid with valid attributes" do
      catalog = Catalog.new(
        identifier: "test-catalog",
        name: "Test Catalog",
        start_date: Date.today,
        end_date: Date.today + 1.year,
        active: true
      )
      expect(catalog).to be_valid
    end
  end

  describe "associations behavior" do
    let(:catalog) { create(:catalog) }

    it "has many sections" do
      section1 = catalog.sections.create!(
        identifier: "section-1",
        name: "Section 1",
        display_order: 0
      )
      section2 = catalog.sections.create!(
        identifier: "section-2",
        name: "Section 2",
        display_order: 1
      )

      expect(catalog.sections.count).to eq(2)
      expect(catalog.sections).to include(section1, section2)
    end

    it "destroys associated sections when destroyed" do
      section = catalog.sections.create!(
        identifier: "section-1",
        name: "Section 1",
        display_order: 0
      )

      catalog.destroy
      expect(Section.find_by(id: section.id)).to be_nil
    end
  end
end
