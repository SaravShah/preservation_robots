# Robot package to run under multiplexing infrastructure
module Robots
  # Use DorRepo/SdrRepo to match the workflow repo (and avoid name collision with Dor module)
  module SdrRepo
    # The workflow package name - match the actual workflow name, minus ending WF (using CamelCase)
    module PreservationIngest
      # Clean up workspace; transfer control back to accessioning by updating accessionWF sdr-ingest-received step
      class CompleteIngest < Base
        ROBOT_NAME = 'complete-ingest'.freeze

        def initialize(opts = {})
          super(REPOSITORY, WORKFLOW_NAME, ROBOT_NAME, opts)
        end

        def perform(druid)
          LyberCore::Log.debug("#{ROBOT_NAME} #{druid} starting")
          @druid = druid # for base class attr_accessor
          complete_ingest
        end

        private

        def complete_ingest
          remove_deposit_bag
          # common_accessioning workflow blocks after it queues up preservation workflow for object
          #   until it receives this signal
          update_accession_workflow
        end

        def remove_deposit_bag
          deposit_bag_pathname.rmtree
        rescue StandardError => e
          errmsg = "Error completing ingest for #{druid}: failed to remove deposit bag (#{deposit_bag_pathname}): " \
            "#{e.message}\n + e.backtrace.join('\n')"
          LyberCore::Log.error(errmsg)
          raise(ItemError, errmsg)
        end

        def update_accession_workflow
          opts = {
            elapsed: 1,
            note: "#{WORKFLOW_NAME} completed on #{Socket.gethostname}"
          }
          workflow_service.update_workflow_status('dor', druid, 'accessionWF', 'sdr-ingest-received', 'completed', opts)
        rescue Dor::WorkflowException => e
          errmsg = "Error completing ingest for #{druid}: failed to update " \
            "accessionWF:sdr-ingest-received to completed: #{e.message}\n#{e.backtrace.join('\n')}"
          LyberCore::Log.error(errmsg)
          raise(ItemError, errmsg)
        end
      end
    end
  end
end
