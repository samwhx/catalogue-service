class ItemSerializer
  include JSONAPI::Serializer

  set_type :item

  attributes :sku, :name, :description, :currency, :display_order, :active, :image_url

  attribute :price do |item|
    item.price.to_s
  end

  attribute :options, if: proc { |_record, params| params && params[:options_json].present? } do |_item, params|
    params[:options_json]
  end
end
