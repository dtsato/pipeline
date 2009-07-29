module Pipeline
  module TransactionalAttribute
    def self.included (base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def transactional_attrs(*attributes)
        attributes.each do |attribute|
          class_eval <<-EOD
            def #{attribute.to_s}=(value)
              ActiveRecord::Base.transaction(:requires_new => true) do
                write_attribute('#{attribute.to_s}', value)
                save!
              end
            end
          EOD
        end
      end
      
      alias_method :transactional_attr, :transactional_attrs
    end
  end
end

ActiveRecord::Base.send(:include, Pipeline::TransactionalAttribute)