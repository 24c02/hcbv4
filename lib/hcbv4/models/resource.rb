# frozen_string_literal: true

module HCBV4
  module Resource
    def require_client!
      raise Error, "No client attached to this #{self.class.name.split("::").last}" unless _client
    end

    module ClassMethods
      def of_id(id, client:, **extra)
        attrs = members.to_h { |m| [m, nil] }
        attrs[:id] = id
        attrs[:_client] = client
        attrs.merge!(extra.slice(*members))
        new(**attrs)
      end
    end

    def self.included(base)
      base.extend(ClassMethods) if base.respond_to?(:members)
    end
  end
end
