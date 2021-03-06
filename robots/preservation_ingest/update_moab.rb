# Robot package to run under multiplexing infrastructure
module Robots
  # Use DorRepo/SdrRepo to match the workflow repo (and avoid name collision with Dor module)
  module SdrRepo
    # The workflow package name - match the actual workflow name, minus ending WF (using CamelCase)
    module PreservationIngest
      # Robot for ingesting deposit bag into Moab object (creating a new version)
      class UpdateMoab < Base
        ROBOT_NAME = 'update-moab'.freeze

        def initialize(opts={})
          super(REPOSITORY, WORKFLOW_NAME, ROBOT_NAME, opts)
        end

        def perform(druid)
          @druid = druid # for base class attr_accessor
          update_moab
        end

        private

        def update_moab
          LyberCore::Log.debug("#{ROBOT_NAME} #{druid} starting")
          new_version = moab_object.ingest_bag
          result = new_version.verify_version_storage
          return if result.verified
          LyberCore::Log.info result.to_json(false)
          raise(ItemError, "Failed verification for #{result.entity}")
        end
      end
    end
  end
end
