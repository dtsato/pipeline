module Pipeline
  module Symbolise
    def self.included (base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def symbolise(*attributes)
        attributes.each do |attribute|
          attribute = attribute.to_s
          class_eval("def #{attribute}; read_symbolised_attribute('#{attribute}'); end")
          class_eval("def #{attribute}= (value); write_symbolised_attribute('#{attribute}', value); end")
        end
      end
    end

    def read_symbolised_attribute(attr_name)
      read_attribute(attr_name).to_sym rescue nil
    end
    
    def write_symbolised_attribute(attr_name, value)
      write_attribute(attr_name, (value.to_sym && value.to_sym.to_s rescue nil))
    end
  end
end

class Symbol
  def quoted_id
    "'#{ActiveRecord::Base.connection.quote_string(self.to_s)}'"
  end
end

ActiveRecord::Base.send(:include, Pipeline::Symbolise)