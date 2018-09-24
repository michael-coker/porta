# frozen_string_literal: true

module ServiceDiscovery
  module ModelExtensions
    module Service
      def self.included(base)
        base.class_eval do
          attr_accessor :source
          attr_accessor :namespace
        end
      end

      def import_cluster_service_endpoint(cluster_service)
        proxy.save_and_deploy(
          api_backend: cluster_service.endpoint,
          api_test_path: "/#{cluster_service.path}"
        )
      end

      def import_cluster_active_docs(cluster_service)
        return unless cluster_service.oas?

        spec_content = cluster_service.specification
        return if spec_content.blank?

        provider.api_docs_services.create({ name: cluster_service.name,
                                            body: spec_content,
                                            published: true,
                                            skip_swagger_validations: true })
      end
    end
  end
end
