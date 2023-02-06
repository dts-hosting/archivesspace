require_relative 'mixins/publishable'

class FileVersion < Sequel::Model(:file_version)
  include ASModel
  include Publishable
  include Representative

  corresponds_to JSONModel(:file_version)

  def before_validation
    super

    # Yale stuff
    #
    # Uniq constraint for only 1xdisplay thumbnail per DO
    # only works if non-thumbnail file versions have a null
    # is_display_thumbnail column value. See is_representative
    # for similar stupid.
    self.is_display_thumbnail = nil if self.is_display_thumbnail != 1
  end

  def representative_for_types
    { is_representative: [:digital_object] }
  end

  def self.handle_publish_flag(ids, val)
    ASModel.update_publish_flag(self.filter(:id => ids), val)
  end

  set_model_scope :global

  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super

    jsons.zip(objs).each do |json, obj|
      json["identifier"] = obj[:id].to_s
    end

    jsons
  end

  def validate
    is_published = false
    if self[:publish] == true || self[:publish] == 1
      is_published = true
    end

    is_representative = false
    if self[:is_representative] == true || self[:is_representative] == 1
      is_representative = true
    end

    if !is_published && is_representative
      raise Sequel::ValidationFailed.new("File version must be published to be representative.")
    end

    # is_display_thumbnail added by plugin `yale_staff_customizations`
    if self[:is_display_thumbnail] == true || self[:is_display_thumbnail] == 1
      validates_unique([:is_display_thumbnail, :digital_object_id],
                       :message => "A digital object can only have one display thumbnail file version")
      map_validation_to_json_property([:is_display_thumbnail, :digital_object_id], :is_display_thumbnail)
    end

    super
  end

end
