class Item < ApplicationRecord
  belongs_to :section
  has_many :options, dependent: :destroy

  validates :sku, presence: true, uniqueness: true
  validates :section_id, presence: true
  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true
  validates :display_order, presence: true

  scope :active, -> { where(active: true) }
end
