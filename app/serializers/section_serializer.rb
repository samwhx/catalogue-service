class SectionSerializer
  include JSONAPI::Serializer

  set_type :section

  attributes :identifier, :name, :description, :display_order, :active, :image_url

  attribute :sub_sections, if: proc { |_record, params| params && params[:sub_sections_json].present? } do |_section, params|
    params[:sub_sections_json]
  end

  attribute :items, if: proc { |_record, params| params && params[:items_json].present? } do |_section, params|
    params[:items_json]
  end
end
