class OptionSerializer
  include JSONAPI::Serializer

  set_type :option

  attributes :name, :description, :currency, :display_order, :active

  attribute :price do |option|
    option.price.to_s
  end
end
