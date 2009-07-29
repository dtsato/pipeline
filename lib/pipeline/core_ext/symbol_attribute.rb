module Pipeline
  module SymbolAttribute
    def self.included (base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def symbol_attrs(*attributes)
        attributes.each do |attribute|
          class_eval <<-EOD
            def #{attribute.to_s}
              read_attribute('#{attribute.to_s}').to_sym rescue nil
            end
          EOD
        end
      end
      
      alias_method :symbol_attr, :symbol_attrs
    end
  end
end

class Symbol
  def quoted_id
    "'#{ActiveRecord::Base.connection.quote_string(self.to_s)}'"
  end
end

ActiveRecord::Base.send(:include, Pipeline::SymbolAttribute)