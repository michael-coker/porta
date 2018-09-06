# frozen_string_literal: true

require 'test_helper'

module ServiceDiscovery
  class ClusterServiceTest < ActiveSupport::TestCase
    include TestHelpers::ServiceDiscovery

    setup do
      @cluster_service_data = {
        metadata: {
          name: 'fake-api',
          namespace: 'fake-project',
          selfLink: '/api/v1/namespaces/fake-project/services/fake-api',
          uid: 'bc6ad9cd-99f2-43a3-91b2-93b7038b0454',
          resourceVersion: '40582387',
          creationTimestamp: '2018-07-17T14:18:55Z',
          labels: {
            :'discovery.3scale.net/discoverable' => 'true',
            app: 'fake-api',
            template: 'fake-template'
          },
          annotations: {
            :'discovery.3scale.net/scheme' => 'http',
            :'discovery.3scale.net/path' => 'api',
            :'discovery.3scale.net/description-path' => 'api/doc'
          }
        },
        spec: {
          ports: [{ name: 'http', protocol: 'TCP', port: 8080, targetPort: 8081 }],
          selector: { app: 'fake-api' },
          clusterIP: '122.50.171.300',
          type: 'ClusterIP',
          sessionAffinity: 'None'
        },
        status: { loadBalancer: {} }
      }
      @cluster_service = ClusterService.new(cluster_service(@cluster_service_data))
    end

    test 'discoverable?' do
      assert @cluster_service.discoverable?

      undiscoverable_cluster_service_data = @cluster_service_data.dup
      undiscoverable_cluster_service_data[:metadata][:labels].delete(:'discovery.3scale.net/discoverable')
      undiscoverable_cluster_service = ClusterService.new(cluster_service(undiscoverable_cluster_service_data))
      refute undiscoverable_cluster_service.discoverable?
    end

    test 'scheme' do
      # default to port's name
      assert_equal 'http', @cluster_service.scheme

      @cluster_service.stubs(port: { name: 'https', protocol: 'TCP', port: 8080, targetPort: 8081 })
      assert_equal 'https', @cluster_service.scheme

      # fallback to annotation
      @cluster_service.stubs(port: { protocol: 'TCP', port: 8080, targetPort: 8081 })
      assert_equal 'http', @cluster_service.scheme

      @cluster_service.stubs(annotated_scheme: 'https', port: { protocol: 'TCP', port: 8080, targetPort: 8081 })
      assert_equal 'https', @cluster_service.scheme

      # fallback to 'http'
      @cluster_service.stubs(annotated_scheme: nil, port: { protocol: 'TCP', port: 8080, targetPort: 8081 })
      assert_equal 'http', @cluster_service.scheme
    end

    test 'path' do
      assert_equal 'api', @cluster_service.path
    end

    test 'target port' do
      assert_equal 8081, @cluster_service.port_number.to_i
    end

    test 'multiple ports specified' do
      multiple_ports_service_data = @cluster_service_data.dup.deep_merge(spec: multiple_ports)
      multiple_ports_service = ClusterService.new(cluster_service(multiple_ports_service_data))
      assert_equal 8443, multiple_ports_service.port_number.to_i
    end

    test 'port enforced through annotation' do
      multiple_ports_service_data = @cluster_service_data.dup.deep_merge(spec: multiple_ports)

      %w[443 https].each do |annotated_port|
        annotated_port_service_data = multiple_ports_service_data.deep_merge(metadata: { annotations: { :'discovery.3scale.net/port' => annotated_port }})
        annotated_port_service = ClusterService.new(cluster_service(annotated_port_service_data))
        assert_equal 8443, annotated_port_service.port_number.to_i
      end

      %w[80 http].each do |annotated_port|
        annotated_port_service_data = multiple_ports_service_data.deep_merge(metadata: { annotations: { :'discovery.3scale.net/port' => annotated_port }})
        annotated_port_service = ClusterService.new(cluster_service(annotated_port_service_data))
        assert_equal 8080, annotated_port_service.port_number.to_i
      end
    end

    test 'non-specified annotated port' do
      multiple_unnamed_ports = { ports: multiple_ports[:ports].map { |port| port.slice(:protocol, :port, :targetPort) } }
      multiple_unnamed_ports_service_data = @cluster_service_data.dup.deep_merge(spec: multiple_unnamed_ports)

      %w[https http default 1234].each do |annotated_port|
        assert_raises ClusterResource::InvalidResourceDefinitionError do
          annotated_port_service_data = multiple_unnamed_ports_service_data.deep_merge(metadata: { annotations: { :'discovery.3scale.net/port' => annotated_port }})
          annotated_port_service = ClusterService.new(cluster_service(annotated_port_service_data))
          annotated_port_service.port_number
        end
      end

      annotated_port_service_data = multiple_unnamed_ports_service_data.deep_merge(metadata: { annotations: { :'discovery.3scale.net/port' => '80' }})
      annotated_port_service = ClusterService.new(cluster_service(annotated_port_service_data))
      assert_equal 8080, annotated_port_service.port_number.to_i
    end

    test 'description path' do
      assert_equal 'api/doc', @cluster_service.description_path
    end

    test 'host' do
      assert_equal 'fake-api.fake-project.svc.cluster.local', @cluster_service.host
    end

    test 'host and port' do
      assert_equal 'fake-api.fake-project.svc.cluster.local:8081', @cluster_service.host_and_port
    end

    test 'root' do
      assert_equal 'http://fake-api.fake-project.svc.cluster.local:8081', @cluster_service.root
    end

    test 'endpoint' do
      assert_equal 'http://fake-api.fake-project.svc.cluster.local:8081/api', @cluster_service.endpoint
    end

    private

    def multiple_ports
      { ports: [
        { name: 'https', protocol: 'TCP', port: 443, targetPort: 8443 },
        { name: 'http', protocol: 'TCP', port: 80, targetPort: 8080 }
      ]}
    end
  end
end
