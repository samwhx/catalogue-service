class CatalogTreeBuilder
  def self.build(catalog)
    new(catalog).build
  end

  def initialize(catalog)
    @catalog = catalog
    @max_depth = ENV.fetch("MAX_SECTION_DEPTH", 5).to_i
  end

  def build
    all_sections = load_sections
    @sections_by_parent = all_sections.group_by(&:parent_id)
    root_sections = @sections_by_parent[nil] || []
    sections_json = root_sections.map { |s| serialize_section(s) }

    serialize_catalog(sections_json)
  end

  private

  def load_sections
    @catalog.sections
            .where(active: true)
            .includes(items: :options)
            .order(:display_order)
            .to_a
  end

  def serialize_catalog(sections_json)
    serialize_with(CatalogSerializer, @catalog, params: { sections_json: sections_json })
  end

  def serialize_section(section, depth = 0)
    return {} if depth >= @max_depth

    sub_sections = find_sub_sections(section, depth)
    items = serialize_items(section)

    serialize_with(SectionSerializer, section, params: { sub_sections_json: sub_sections, items_json: items })
  end

  def find_sub_sections(section, depth)
    return [] if depth >= @max_depth - 1

    active_sorted(@sections_by_parent[section.id] || [])
      .map { |s| serialize_section(s, depth + 1) }
  end

  def serialize_items(section)
    active_sorted(section.items).map do |item|
      options = serialize_collection(active_sorted(item.options), OptionSerializer)
      serialize_with(ItemSerializer, item, params: { options_json: options })
    end
  end

  def active_sorted(collection)
    collection.select(&:active).sort_by(&:display_order)
  end

  def serialize_with(serializer_class, object, params = {})
    serialized = serializer_class.new(object, params).serializable_hash
    extract_attributes(serialized[:data])
  end

  def serialize_collection(collection, serializer_class)
    collection.map { |item| serialize_with(serializer_class, item) }
  end

  def extract_attributes(data_item)
    return {} unless data_item
    { id: data_item[:id], **data_item[:attributes] || {} }
  end
end
