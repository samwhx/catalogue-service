class CatalogSerializer
  include JSONAPI::Serializer

  set_type :catalog

  attributes :identifier, :name, :active

  attribute :start_date do |catalog|
    catalog.start_date&.iso8601
  end

  attribute :end_date do |catalog|
    catalog.end_date&.iso8601
  end

  attribute :created_at do |catalog|
    catalog.created_at.iso8601
  end

  attribute :updated_at do |catalog|
    catalog.updated_at.iso8601
  end

  # Include nested sections in attributes for performance
  attribute :sections, if: proc { |_record, params| params && params[:sections_json].present? } do |_catalog, params|
    params[:sections_json]
  end
end
