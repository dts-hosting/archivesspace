require 'set'

class IndexerCommonConfig

  def self.record_types
    [
      :resource,
      :digital_object,
      :accession,
      :agent_person,
      :agent_software,
      :agent_family,
      :agent_corporate_entity,
      :subject,
      :location,
      :event,
      :top_container,
      :classification,
      :container_profile,
      :location_profile,
      :archival_object,
      :digital_object_component,
      :classification_term,
      :assessment,
      :job
    ]
  end

  def self.global_types
    [
      :agent_person,
      :agent_software,
      :agent_family,
      :agent_corporate_entity,
      :location,
      :subject
    ]
  end

  def self.resolved_attributes
    [
      'location_profile',
      'container_profile',
      'container_locations',
      'subjects',
      'places',

      # EAD export depends on this
      'linked_agents',
      'linked_records',
      'classifications',

      # EAD export depends on this
      'digital_object',
      'agent_representation',
      'repository',
      'repository::agent_representation',
      'related_agents',

      # EAD export depends on this
      'top_container',

      # EAD export depends on this
      'top_container::container_profile',

      # Assessment module depends on these
      'related_agents',
      'records',
      'collections',
      'surveyed_by',
      'reviewer',
      'creator',

      #Accessions module depends on these
      'related_accessions',
    ]
  end

  def self.do_not_index
    # ANW-1065
    # #sanitize_json uses this hash to clean up sensitive data, preventing it from being indexed in the json field in the indexer doc.
    {
        "agent_person"           => {:location => [],
                                     :to_clean => "agent_contacts"},
        "agent_family"           => {:location => [],
                                     :to_clean => "agent_contacts"},
        "agent_corporate_entity" => {:location => [],
                                     :to_clean => "agent_contacts"},
        "agent_software"         => {:location => [],
                                     :to_clean => "agent_contacts"},
    }
  end

  def self.excluded_fields_from_keyword_search
    @@excluded_fields_from_keyword_search ||= Set.new([
      'created_by',
      'last_modified_by',
      'system_mtime',
      'user_mtime',
      'json',
      'types',
      'create_time',
      'date_type',
      'jsonmodel_type',
      'publish',
      'extent_type',
      'language',
      'script',
      'system_generated',
      'suppressed',
      'source',
      'rules',
      'name_order',
    ])

    @@excluded_fields_from_keyword_search
  end


  def self.exclude_from_keyword_search(field_name)
    excluded_fields_from_keyword_search << field_name
  end


  def self.excluded_typed_fields_from_keyword_search
    @@excluded_typed_fields_from_keyword_search ||= {}
    @@excluded_typed_fields_from_keyword_search
  end


  def self.exclude_from_keyword_search(jsonmodel_type, field_name)
    excluded_typed_fields_from_keyword_search[jsonmodel_type.to_s] ||= Set.new
    excluded_typed_fields_from_keyword_search[jsonmodel_type.to_s] << field_name
  end


  def self.excluded_typed_fields_from_public_keyword_search
    @@excluded_typed_fields_from_public_keyword_search ||= {}
    @@excluded_typed_fields_from_public_keyword_search
  end


  def self.exclude_from_public_keyword_search(jsonmodel_type, field_name)
    excluded_typed_fields_from_public_keyword_search[jsonmodel_type.to_s] ||= Set.new
    excluded_typed_fields_from_public_keyword_search[jsonmodel_type.to_s] << field_name
  end
end
