require "rails_helper"

RSpec.describe Section, type: :model do
  let(:catalog) { create(:catalog) }
  subject { build(:section, catalog: catalog) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:identifier) }
    it { is_expected.to validate_uniqueness_of(:identifier) }
    it { is_expected.to validate_presence_of(:catalog_id) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:display_order) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:catalog) }
    it { is_expected.to belong_to(:parent).class_name("Section").optional }
    it { is_expected.to have_many(:sub_sections).class_name("Section").with_foreign_key("parent_id").dependent(:destroy) }
    it { is_expected.to have_many(:items).dependent(:destroy) }
  end

  describe "valid section" do
    it "is valid with valid attributes" do
      section = Section.new(
        identifier: "test-section",
        catalog: catalog,
        name: "Test Section",
        display_order: 0
      )
      expect(section).to be_valid
    end
  end

  describe "associations behavior" do
    it "belongs to catalog" do
      section = create(:section, catalog: catalog)
      expect(section.catalog).to eq(catalog)
    end

    it "has parent section" do
      parent = create(:section, catalog: catalog)
      child = create(:section, catalog: catalog, parent: parent)
      expect(child.parent).to eq(parent)
    end

    it "has sub_sections" do
      parent = create(:section, catalog: catalog)
      child1 = create(:section, catalog: catalog, parent: parent, display_order: 0)
      child2 = create(:section, catalog: catalog, parent: parent, display_order: 1)

      expect(parent.sub_sections.count).to eq(2)
      expect(parent.sub_sections).to include(child1, child2)
    end

    it "has items" do
      section = create(:section, catalog: catalog)
      item1 = create(:item, section: section, display_order: 0)
      item2 = create(:item, section: section, display_order: 1)

      expect(section.items.count).to eq(2)
      expect(section.items).to include(item1, item2)
    end
  end

  describe "circular reference prevention" do
    it "prevents direct self-reference" do
      section = create(:section, catalog: catalog)
      section.parent_id = section.id
      expect(section).not_to be_valid
      expect(section.errors[:parent_id]).to include("cannot create circular reference")
    end

    it "prevents indirect cycle" do
      parent = create(:section, catalog: catalog)
      child = create(:section, catalog: catalog, parent: parent)
      grandchild = create(:section, catalog: catalog, parent: child)

      # Try to make parent a child of grandchild (creates cycle)
      parent.parent_id = grandchild.id
      expect(parent).not_to be_valid
      expect(parent.errors[:parent_id]).to include("cannot create circular reference")
    end
  end

  describe "depth limit" do
    it "respects MAX_SECTION_DEPTH" do
      ENV["MAX_SECTION_DEPTH"] = "2"

      level1 = create(:section, catalog: catalog)
      level2 = create(:section, catalog: catalog, parent: level1)

      # Level 3 should exceed depth limit
      level3 = Section.new(
        identifier: "level-3",
        catalog: catalog,
        parent: level2,
        name: "Level 3",
        display_order: 0
      )
      expect(level3).not_to be_valid
      expect(level3.errors[:parent_id]).to include("exceeds maximum depth of 2")

      ENV.delete("MAX_SECTION_DEPTH")
    end
  end

  describe "#depth" do
    it "returns 0 for root sections" do
      section = create(:section, catalog: catalog)
      expect(section.depth).to eq(0)
    end

    it "calculates correctly for nested sections" do
      level1 = create(:section, catalog: catalog)
      level2 = create(:section, catalog: catalog, parent: level1)
      level3 = create(:section, catalog: catalog, parent: level2)

      expect(level1.depth).to eq(0)
      expect(level2.depth).to eq(1)
      expect(level3.depth).to eq(2)
    end
  end

  describe "scopes" do
    describe ".active" do
      let!(:active_section) { create(:section, catalog: catalog, active: true) }
      let!(:inactive_section) { create(:section, catalog: catalog, active: false) }

      it "returns only active sections" do
        expect(Section.active).to include(active_section)
        expect(Section.active).not_to include(inactive_section)
      end
    end

    describe ".root_sections" do
      let!(:root) { create(:section, catalog: catalog) }
      let!(:child) { create(:section, catalog: catalog, parent: root) }

      it "returns only root sections" do
        expect(Section.root_sections).to include(root)
        expect(Section.root_sections).not_to include(child)
      end
    end
  end
end
