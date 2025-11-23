class Option < ApplicationRecord
  belongs_to :item

  validates :item_id, presence: true
  validates :name, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true
  validates :display_order, presence: true

  scope :active, -> { where(active: true) }
end
