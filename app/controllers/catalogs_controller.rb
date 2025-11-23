class CatalogsController < ApplicationController
  def index
    cache_key = "catalogs:index:#{Catalog.maximum(:updated_at)&.to_i}"
    render_with_cache(cache_key, expires_in: 24.hours) do
      catalogs = Catalog.active.order(:created_at).to_a
      CatalogSerializer.new(catalogs, is_collection: true).serializable_hash
    end
  end

  def show
    catalog = Catalog.active.find_by!(identifier: params[:id])
    cache_key = "catalog:#{catalog.id}:#{catalog.updated_at.to_i}"
    render_with_cache(cache_key, expires_in: 24.hours) do
      CatalogTreeBuilder.build(catalog)
    end
  end
end
