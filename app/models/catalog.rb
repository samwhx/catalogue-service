class Catalog < ApplicationRecord
  has_many :sections, dependent: :destroy

  validates :identifier, presence: true, uniqueness: true
  validates :name, presence: true

  scope :active, -> { where(active: true) }
end
