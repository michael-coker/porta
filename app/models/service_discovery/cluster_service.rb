# frozen_string_literal: true

module ServiceDiscovery
  class ClusterService < NamespacedClusterResource
    # See https://github.com/kubernetes/kubernetes/blob/release-1.4/docs/proposals/service-discovery.md

    DISCOVERY_NAMESPACE = 'discovery.3scale.net'

    def self.discovery_key(field_name)
      "#{DISCOVERY_NAMESPACE}/#{field_name}".to_sym
    end

    def self.discovery_label_selector
      { discovery_key('discoverable') => 'true' }
    end

    def host
      "#{name}.#{namespace}.svc.cluster.local"
    end

    def host_and_port
      [host, port_number.to_s.presence].compact.join(':')
    end

    def root
      "#{scheme}://#{host_and_port}"
    end

    def endpoint
      "#{root}/#{path}"
    end

    def scheme
      port_name =~ /^https?$/ ? port_name : (annotated_scheme || 'http')
    end

    def ports
      (spec[:ports] || []).map(&:to_h)
    end

    def port
      if annotated_port
        ports.find(&port_selector.method(:<=)) || raise(InvalidResourceDefinitionError, 'Service does not specify the port annotated for discovery')
      else
        ports.first
      end
    end

    def port_name
      port[:name]
    end

    def port_number
      port[:targetPort]
    end

    %w[scheme port path description-path].each do |field_name|
      method_name = "annotated_#{field_name.tr('-', '_')}"
      define_method(method_name.to_sym) do
        discovery_annotation(field_name)
      end
    end

    alias path annotated_path
    alias description_path annotated_description_path

    def discoverable?
      discovery_label(:discoverable).to_s == 'true'
    end

    protected

    def discovery_label(field_name)
      labels[self.class.discovery_key(field_name)]
    end

    def discovery_annotation(field_name)
      annotations[self.class.discovery_key(field_name)]
    end

    def port_selector
      case annotated_port
      when /\A\d+\z/
        { port: annotated_port.to_i }
      else
        { name: annotated_port }
      end
    end
  end
end