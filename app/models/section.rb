class Section < ApplicationRecord
  belongs_to :catalog
  belongs_to :parent, class_name: "Section", optional: true
  has_many :sub_sections, class_name: "Section", foreign_key: "parent_id", dependent: :destroy
  has_many :items, dependent: :destroy

  validates :identifier, presence: true, uniqueness: true
  validates :catalog_id, presence: true
  validates :name, presence: true
  validates :display_order, presence: true
  validate :no_circular_reference
  validate :depth_limit

  scope :active, -> { where(active: true) }
  scope :root_sections, -> { where(parent_id: nil) }

  def depth
    return 0 if parent_id.nil?
    parent.depth + 1
  end

  private

  def no_circular_reference
    return unless parent_id

    ancestor_ids = Set.new([ id ])
    current = parent
    while current
      if ancestor_ids.include?(current.id)
        errors.add(:parent_id, "cannot create circular reference")
        break
      end
      ancestor_ids.add(current.id)
      current = current.parent
    end
  end

  def depth_limit
    return unless parent_id

    max_depth = ENV.fetch("MAX_SECTION_DEPTH", 5).to_i
    if depth >= max_depth
      errors.add(:parent_id, "exceeds maximum depth of #{max_depth}")
    end
  end
end
