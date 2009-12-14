module Pipeline
  # Extends ActiveRecord::Base to save and retrieve symbol attributes as strings.
  #
  # Example:
  #   class Card < ActiveRecord::Base
  #     symbol_attrs :rank, :suit
  #   end
  #
  #   card = Card.new(:rank => 'jack', :suit => 'hearts')
  #   card.rank # => :jack
  #   card.suit # => :hearts
  #
  # It also allow symbol attributes to be used on ActiveRecord #find conditions:
  #
  #   Card.find(:all, :conditions => ['suit = ?', :clubs])
  module SymbolAttribute
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods #:nodoc:
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

class Symbol #:nodoc:
  def quoted_id
    "'#{ActiveRecord::Base.connection.quote_string(self.to_s)}'"
  end
end

ActiveRecord::Base.send(:include, Pipeline::SymbolAttribute)