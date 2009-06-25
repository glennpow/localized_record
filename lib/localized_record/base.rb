module LocalizedRecord
  module Base
    def self.included(base)
      base.extend(MacroMethods)
    end
  
    module MacroMethods
      def has_localized(*args)
        unless self.is_a? LocalizedRecord::Base::ClassMethods
          extend LocalizedRecord::Base::ClassMethods
        end
        
        cattr_accessor :localized_mode

        options = args.extract_options!
        self.class_localized_attributes.concat(args.map(&:to_s)) if args.any? && args.first != :all
        self.localized_mode = options[:mode]
        
        localized_attributes.each do |attribute|
          define_method attribute do |*args|
            options = args.extract_options!
            mode = self.class.localized_mode
            value = super
            
            if options[:unlocalized] != true && LocalizedRecord.localized?(value, mode)
              locale = (options[:locale] || I18n.locale).to_s

              begin
                translations = LocalizedRecord.s_to_translations(value, mode)
              rescue ArgumentError => e
                raise InvalidTranslationValue.new(locale, self, attribute, value, options)
              end
              if (translation_value = translations[locale]).nil?
                if (translation_value = translations[default_locale.to_s]).nil?
                  translation_value = translations.values.first
                end
              end
              
              unless translation_value.nil?
                value = translation_value
              else
                raise InvalidTranslationValue.new(locale, self, attribute, value, options)
              end
            end
            
            return value
          end

          define_method "#{attribute}=" do |value|
            value = LocalizedRecord.translations_to_s(value, self.class.localized_mode) if value.is_a?(Hash)
            super(value)
          end
        end
      end
    end
  
    module ClassMethods
      def class_localized_attributes
        attributes = read_inheritable_attribute(:class_localized_attributes)
        write_inheritable_attribute(:class_localized_attributes, attributes = []) if attributes.nil?
        return attributes
      end

      def localized_attributes
        attributes = read_inheritable_attribute(:class_localized_attributes)
        if attributes.blank?
          attributes = []
          string_columns = self.columns.select { |c| c.type == :text or c.type == :string }
          attributes = string_columns.collect { |c| c.name }
        end
        return attributes
      end
    end
  end

  class LocalizedAttribute
    attr_reader :translations
    
    def initialize(record = nil, attribute = nil, default_locale = nil)
      @translations = {}
      if record && attribute
        mode = record.class.localized_mode
        default_locale = (default_locale || I18n.default_locale).to_s
        value = record.send(attribute, :unlocalized => true)
        if LocalizedRecord.localized?(value, mode)
          @translations = LocalizedRecord.s_to_translations(value, mode)
        else
          @translations[default_locale] = value
        end
      end
    rescue ArgumentError => e
      InvalidTranslationValue.new(locale, self, attribute, value, options)
    end
  
    def method_missing(method, *args)
      @translations[method.to_s] || ""
    end
    
    def errors
      ActiveRecord::Errors.new(self) # TODO?
    end
  end
end

ActiveRecord::Base.send(:include, LocalizedRecord::Base) if defined?(ActiveRecord::Base)