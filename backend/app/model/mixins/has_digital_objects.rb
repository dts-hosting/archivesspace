module HasDigitalObjects

  def self.included(base)
    base.extend(ClassMethods)
  end


  module ClassMethods

    def sequel_to_jsonmodel(objs, opts = {})
      jsons = super

      if self == Resource
        # A Resource is marked as having a digital object if it, or any of its
        # descendant Archival Objects, has a digital object instance.
        resources_with_descendant_digital_objects = Set.new

        # Check resource instances...
        resources_with_descendant_digital_objects +=
          Resource
            .join(:instance, Sequel.qualify(:instance, :resource_id) => Sequel.qualify(:resource, :id))
            .join(:instance_do_link_rlshp, Sequel.qualify(:instance_do_link_rlshp, :instance_id) => Sequel.qualify(:instance, :id))
            .join(:digital_object, Sequel.qualify(:digital_object, :id) => Sequel.qualify(:instance_do_link_rlshp, :digital_object_id))
            .filter(Sequel.qualify(:resource, :id) => objs.map(&:id))
            .filter(Sequel.qualify(:digital_object, :publish) => 1)
            .select(Sequel.qualify(:resource, :id))
            .distinct
            .map {|row| row[:id]}

        # Check resource's children instances...
        resources_with_descendant_digital_objects +=
          Resource
            .join(:archival_object,
                  Sequel.qualify(:resource, :id) => Sequel.qualify(:archival_object, :root_record_id),
                  Sequel.qualify(:archival_object, :publish) => 1)
            .join(:instance, Sequel.qualify(:instance, :archival_object_id) => Sequel.qualify(:archival_object, :id))
            .join(:instance_do_link_rlshp, Sequel.qualify(:instance_do_link_rlshp, :instance_id) => Sequel.qualify(:instance, :id))
            .join(:digital_object, Sequel.qualify(:digital_object, :id) => Sequel.qualify(:instance_do_link_rlshp, :digital_object_id))
            .filter(Sequel.qualify(:resource, :id) => objs.map(&:id))
            .filter(Sequel.qualify(:digital_object, :publish) => 1)
            .select(Sequel.qualify(:resource, :id))
            .distinct
            .map {|row| row[:id]}

        jsons.zip(objs).each do |json, obj|
          json[:has_published_digital_objects] = resources_with_descendant_digital_objects.include?(obj.id)
        end
      elsif self == ArchivalObject
        # An Archival Object is marked as having digital objects if one of its instances
        # is a digital object.
        archival_object_with_published_digital_objects = Set.new(
          ArchivalObject
            .join(:instance, Sequel.qualify(:instance, :archival_object_id) => Sequel.qualify(:archival_object, :id))
            .join(:instance_do_link_rlshp, Sequel.qualify(:instance_do_link_rlshp, :instance_id) => Sequel.qualify(:instance, :id))
            .join(:digital_object, Sequel.qualify(:digital_object, :id) => Sequel.qualify(:instance_do_link_rlshp, :digital_object_id))
            .filter(Sequel.qualify(:archival_object, :id) => objs.map(&:id))
            .filter(Sequel.qualify(:digital_object, :publish) => 1)
            .select(Sequel.qualify(:archival_object, :id))
            .distinct
            .map {|row| row[:id]}
        )

        jsons.zip(objs).each do |json, obj|
          json[:has_published_digital_objects] = archival_object_with_published_digital_objects.include?(obj.id)
        end
      end


      jsons
    end
  end
end
