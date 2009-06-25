module LocalizedRecord
  module Helper
    def localization_select(form_or_record, options = {})
      locales = options.delete(:locales) || LocalizedRecord.available_locales
      if (locales.is_a?(Array) || locales.is_a?(Hash))
        default_locale = (options.delete(:default_locale) || I18n.default_locale).to_s
        record = case form_or_record
        when ActionView::Helpers::FormBuilder
          form_or_record.object
        else
          form_or_record
        end
        record_id = record.try(:id) || 0

        choices = case locales
        when Array
          options_for_select(locales.map { |locale| [ locale.to_s, locale.to_s ] }, default_locale)
        when Hash
          options_for_select(locales.map { |locale, name| [ name, locale.to_s ] }, default_locale)
        end
        select_options = options.merge(
          :disabled => locales.length <= 1,
          :onchange => "$$('.localized-field-#{record_id}').invoke('hide'); $$('.localized-field-#{record_id}-' + this.options[this.selectedIndex].value).invoke('show')"
        )
        select_tag("localization_select_#{record_id}", choices, select_options)
      end
    end

    def localized_fields_for(form_or_record, method, options = {}, &block)
      locales = options.delete(:locales) || LocalizedRecord.available_locales
      default_locale = (options.delete(:default_locale) || I18n.default_locale).to_s
      record = case form_or_record
      when ActionView::Helpers::FormBuilder
        form_or_record.object
      else
        form_or_record
      end
      record_id = record.try(:id) || 0
      
      proxy = LocalizedRecord::LocalizedAttribute.new(record, method, default_locale)

      capture do
        case form_or_record
        when ActionView::Helpers::FormBuilder
          form_or_record.fields_for(method, proxy) do |f|
            locales_for_localized_field(f, record_id, locales, default_locale, &block)
          end
        else
          fields_for(form_or_record, method, proxy) do |f|
            locales_for_localized_field(f, record_id, locales, default_locale, &block)
          end
        end
        output_buffer
      end
    end
    
    def localized_text_field(form_or_record, method, field_options = {}, localized_options = {})
      localized_fields_for(form_or_record, method, localized_options) do |f, locale, locale_name|
        localized_field_options = {}
        field_options.each do |key, value|
          case value
          when Proc
            localized_field_options[key] = value.call(locale, locale_name)
          else
            localized_field_options[key] = value
          end
        end
        f.text_field(locale, localized_field_options)
      end
    end
    
    def localized_text_area(form_or_record, method, field_options = {}, localized_options = {})
      localized_fields_for(form_or_record, method, localized_options) do |f, locale, locale_name|
        localized_field_options = {}
        field_options.each do |key, value|
          case value
          when Proc
            localized_field_options[key] = value.call(locale, locale_name)
          else
            localized_field_options[key] = value
          end
        end
        f.text_area(locale, localized_field_options)
      end
    end

    def locales_for_localized_field(form, record_id, locales, default_locale, &block)
      locale_codes = case locales
      when Array
        locales.map(&:to_s)
      when Hash
        locales.stringify_keys!
        locales.keys
      else
        []
      end
      locale_codes.each do |locale|
        locale_name = locales.is_a?(Hash) ? locales[locale] : locale
        display = (locale == default_locale) ? "block" : "none"
        content = block_called_from_erb?(block) ? capture(form, locale, locale_name, &block) : yield(form, locale, locale_name)
        concat(content_tag(:div, content, :class => "localized-field-#{record_id} localized-field-#{record_id}-#{locale}", :style => "display: #{display}"))
      end
    end
  end
end

ActionView::Base.send :include, LocalizedRecord::Helper if defined?(ActionView::Base)