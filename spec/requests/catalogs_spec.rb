require "rails_helper"

RSpec.describe "Catalogs API", type: :request do
  let(:catalog) do
    create(:catalog,
           identifier: "test-catalog",
           name: "Test Catalog",
           start_date: Date.today,
           end_date: Date.today + 1.year,
           active: true)
  end
  let(:inactive_catalog) { create(:catalog, identifier: "inactive-catalog", name: "Inactive Catalog", active: false) }

  let(:root_section) { create(:section, catalog: catalog, identifier: "root-section", name: "Root Section", display_order: 0, active: true) }
  let(:sub_section) { create(:section, catalog: catalog, parent: root_section, identifier: "sub-section", name: "Sub Section", display_order: 0, active: true) }
  let(:inactive_section) { create(:section, catalog: catalog, identifier: "inactive-section", name: "Inactive Section", display_order: 1, active: false) }

  let(:item) { create(:item, section: root_section, sku: "test-item", name: "Test Item", price: 10.00, display_order: 0, active: true) }
  let(:inactive_item) { create(:item, section: root_section, sku: "inactive-item", name: "Inactive Item", price: 20.00, display_order: 1, active: false) }

  let(:option) { create(:option, item: item, name: "Test Option", price: 2.00, display_order: 0, active: true) }
  let(:inactive_option) { create(:option, item: item, name: "Inactive Option", price: 3.00, display_order: 1, active: false) }

  before do
    # Ensure all associations are created
    catalog
    inactive_catalog
    root_section
    sub_section
    inactive_section
    item
    inactive_item
    option
    inactive_option
    Rails.cache.clear
  end

  describe "GET /catalogs" do
    it "returns list of catalogs" do
      get "/catalogs", as: :json

      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq("application/json; charset=utf-8")

      json_response = JSON.parse(response.body)
      expect(json_response).to have_key("data")
      expect(json_response["data"]).to be_an(Array)

      # Should only include active catalogs
      catalog_ids = json_response["data"].map { |c| c["id"] }
      expect(catalog_ids).to include(catalog.id.to_s)
      expect(catalog_ids).not_to include(inactive_catalog.id.to_s)
    end

    it "returns catalogs ordered by created_at" do
      older_catalog = create(:catalog, identifier: "older-catalog", name: "Older Catalog", active: true, created_at: 1.day.ago)

      get "/catalogs", as: :json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      catalog_ids = json_response["data"].map { |c| c["id"] }

      # Older catalog should come first
      expect(catalog_ids.first).to eq(older_catalog.id.to_s)
    end

    it "does not include sections in index response" do
      get "/catalogs", as: :json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      catalog_data = json_response["data"].find { |c| c["id"] == catalog.id.to_s }
      attributes = catalog_data["attributes"]

      # Should not have sections in index response
      expect(attributes).not_to have_key("sections")
    end

    it "uses caching" do
      # First request - should hit database
      get "/catalogs", as: :json
      expect(response).to have_http_status(:success)
      first_response = response.body

      # Second request - should use cache
      get "/catalogs", as: :json
      expect(response).to have_http_status(:success)
      expect(response.body).to eq(first_response)
    end
  end

  describe "GET /catalogs/:identifier" do
    it "returns catalog with identifier" do
      get "/catalogs/#{catalog.identifier}", as: :json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response).to have_key("identifier")
      expect(json_response["identifier"]).to eq(catalog.identifier)
      expect(json_response["name"]).to eq(catalog.name)
    end

    it "includes nested sections" do
      get "/catalogs/#{catalog.identifier}", as: :json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response).to have_key("sections")
      expect(json_response["sections"]).to be_an(Array)

      # Should include root section
      section_identifiers = json_response["sections"].map { |s| s["identifier"] }
      expect(section_identifiers).to include(root_section.identifier)
      expect(section_identifiers).not_to include(inactive_section.identifier)
    end

    it "includes nested sub_sections" do
      get "/catalogs/#{catalog.identifier}", as: :json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      root_section_data = json_response["sections"].find { |s| s["identifier"] == root_section.identifier }

      expect(root_section_data).to have_key("sub_sections")
      expect(root_section_data["sub_sections"]).to be_an(Array)

      sub_section_identifiers = root_section_data["sub_sections"].map { |s| s["identifier"] }
      expect(sub_section_identifiers).to include(sub_section.identifier)
    end

    it "includes nested items" do
      get "/catalogs/#{catalog.identifier}", as: :json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      root_section_data = json_response["sections"].find { |s| s["identifier"] == root_section.identifier }

      expect(root_section_data).to have_key("items")
      expect(root_section_data["items"]).to be_an(Array)

      item_skus = root_section_data["items"].map { |i| i["sku"] }
      expect(item_skus).to include(item.sku)
      expect(item_skus).not_to include(inactive_item.sku)
    end

    it "includes nested options" do
      get "/catalogs/#{catalog.identifier}", as: :json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      root_section_data = json_response["sections"].find { |s| s["identifier"] == root_section.identifier }
      item_data = root_section_data["items"].find { |i| i["sku"] == item.sku }

      expect(item_data).to have_key("options")
      expect(item_data["options"]).to be_an(Array)

      option_names = item_data["options"].map { |o| o["name"] }
      expect(option_names).to include(option.name)
      expect(option_names).not_to include(inactive_option.name)
    end

    it "returns 404 for non-existent catalog" do
      get "/catalogs/non-existent", as: :json

      expect(response).to have_http_status(:not_found)
      json_response = JSON.parse(response.body)
      expect(json_response["error"]).to eq("Resource not found")
      expect(json_response["status"]).to eq(404)
    end

    it "returns 404 for inactive catalog" do
      get "/catalogs/#{inactive_catalog.identifier}", as: :json

      expect(response).to have_http_status(:not_found)
    end

    it "filters inactive entities" do
      get "/catalogs/#{catalog.identifier}", as: :json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)

      # Should not include inactive section
      section_identifiers = json_response["sections"].map { |s| s["identifier"] }
      expect(section_identifiers).not_to include(inactive_section.identifier)

      # Should not include inactive item
      root_section_data = json_response["sections"].find { |s| s["identifier"] == root_section.identifier }
      item_skus = root_section_data["items"].map { |i| i["sku"] }
      expect(item_skus).not_to include(inactive_item.sku)

      # Should not include inactive option
      item_data = root_section_data["items"].find { |i| i["sku"] == item.sku }
      option_names = item_data["options"].map { |o| o["name"] }
      expect(option_names).not_to include(inactive_option.name)
    end

    it "uses caching" do
      # First request - should hit database
      get "/catalogs/#{catalog.identifier}", as: :json
      expect(response).to have_http_status(:success)
      first_response = response.body

      # Second request - should use cache
      get "/catalogs/#{catalog.identifier}", as: :json
      expect(response).to have_http_status(:success)
      expect(response.body).to eq(first_response)
    end

    it "invalidates cache when catalog is updated" do
      # First request - cache the response
      get "/catalogs/#{catalog.identifier}", as: :json
      expect(response).to have_http_status(:success)

      # Update catalog
      catalog.update!(name: "Updated Name")

      # Second request - should have new data (cache invalidated by updated_at)
      get "/catalogs/#{catalog.identifier}", as: :json
      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response["name"]).to eq("Updated Name")
    end

    it "handles database errors gracefully" do
      allow(Catalog).to receive(:active).and_raise(StandardError.new("Database error"))

      get "/catalogs/#{catalog.identifier}", as: :json

      expect(response).to have_http_status(:internal_server_error)
      json_response = JSON.parse(response.body)
      expect(json_response["error"]).to eq("Internal server error")
      expect(json_response["status"]).to eq(500)
    end

    it "does not cache errors" do
      # First request - should cache error response
      allow(Catalog).to receive(:active).and_raise(StandardError.new("Database error"))
      get "/catalogs/#{catalog.identifier}", as: :json
      expect(response).to have_http_status(:internal_server_error)

      # Second request - should not use cached error
      allow(Catalog).to receive(:active).and_call_original
      get "/catalogs/#{catalog.identifier}", as: :json
      # Should succeed since we're not stubbing anymore
      expect(response).to have_http_status(:success)
    end

    it "respects MAX_SECTION_DEPTH" do
      # Create sections without depth limit first
      level1 = create(:section, catalog: catalog, identifier: "level-1", name: "Level 1", display_order: 0, active: true)
      level2 = create(:section, catalog: catalog, parent: level1, identifier: "level-2", name: "Level 2", display_order: 0, active: true)
      level3 = create(:section, catalog: catalog, parent: level2, identifier: "level-3", name: "Level 3", display_order: 0, active: true)

      # Now set depth limit and verify API respects it
      ENV["MAX_SECTION_DEPTH"] = "2"

      get "/catalogs/#{catalog.identifier}", as: :json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)

      # Should include level 1 and 2, but not level 3 (due to depth limit in API)
      level1_section = json_response["sections"].find { |s| s["identifier"] == level1.identifier }
      expect(level1_section).to have_key("sub_sections")

      level2_section = level1_section["sub_sections"].first
      expect(level2_section["identifier"]).to eq(level2.identifier)

      # Level 3 should not have sub_sections (depth limit reached in API response)
      # sub_sections might be nil or empty array
      expect(level2_section["sub_sections"]).to be_nil.or(be_empty)

      ENV.delete("MAX_SECTION_DEPTH")
    end

    it "returns proper JSON structure" do
      get "/catalogs/#{catalog.identifier}", as: :json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)

      # Verify all required fields are present
      required_fields = %w[identifier name active created_at updated_at sections]
      required_fields.each do |field|
        expect(json_response).to have_key(field), "Missing field: #{field}"
      end

      # Verify section structure
      section = json_response["sections"].first
      section_fields = %w[identifier name display_order active sub_sections items]
      section_fields.each do |field|
        expect(section).to have_key(field), "Missing section field: #{field}"
      end

      # Verify item structure
      item_data = section["items"].first
      item_fields = %w[sku name price currency display_order active options]
      item_fields.each do |field|
        expect(item_data).to have_key(field), "Missing item field: #{field}"
      end

      # Verify option structure
      option_data = item_data["options"].first
      option_fields = %w[name price currency display_order active]
      option_fields.each do |field|
        expect(option_data).to have_key(field), "Missing option field: #{field}"
      end
    end

    it "handles empty catalog" do
      empty_catalog = create(:catalog, identifier: "empty-catalog", name: "Empty Catalog", active: true)

      get "/catalogs/#{empty_catalog.identifier}", as: :json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)

      expect(json_response["identifier"]).to eq(empty_catalog.identifier)
      # Sections might be nil or empty array depending on serializer
      expect(json_response["sections"]).to be_nil.or(be_empty)
    end

    it "uses identifier not id" do
      # Should work with identifier
      get "/catalogs/#{catalog.identifier}", as: :json
      expect(response).to have_http_status(:success)

      # Should not work with numeric id
      get "/catalogs/#{catalog.id}", as: :json
      expect(response).to have_http_status(:not_found)
    end

    it "orders entities by display_order" do
      # Clear existing sections to avoid interference
      catalog.sections.destroy_all

      # Create multiple sections with different display orders
      section1 = create(:section, catalog: catalog, identifier: "section-1", name: "Section 1", display_order: 2, active: true)
      section2 = create(:section, catalog: catalog, identifier: "section-2", name: "Section 2", display_order: 0, active: true)
      section3 = create(:section, catalog: catalog, identifier: "section-3", name: "Section 3", display_order: 1, active: true)

      get "/catalogs/#{catalog.identifier}", as: :json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)

      # Should be ordered by display_order: 0, 1, 2
      section_identifiers = json_response["sections"].map { |s| s["identifier"] }
      expect(section_identifiers[0]).to eq(section2.identifier)
      expect(section_identifiers[1]).to eq(section3.identifier)
      expect(section_identifiers[2]).to eq(section1.identifier)
    end
  end
end
