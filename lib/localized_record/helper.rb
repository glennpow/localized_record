module LocalizedRecord
  module Helper
    def localization_select(options = {})
      locales = (options.delete(:locales) || LocalizedRecord.available_locales).map(&:to_s)
      default_locale = (options.delete(:default_locale) || I18n.default_locale).to_s

      select_options = options.merge(:onchange => "$$('.localized-field').invoke('hide'); $$('.localized-field-' + this.options[this.selectedIndex].value).invoke('show')")
      select_tag("localization_select", options_for_select(locales.map { |locale| [ locale, locale ] }, default_locale), select_options)
    end

    def localized_fields_for(form_or_record, method, options = {}, &block)
      locales = (options.delete(:locales) || LocalizedRecord.available_locales).map(&:to_s)
      default_locale = (options.delete(:default_locale) || I18n.default_locale).to_s
      record = case form_or_record
      when ActionView::Helpers::FormBuilder
        form_or_record.object
      else
        form_or_record
      end
      
      proxy = LocalizedRecord::AttributeProxy.new(record, method, default_locale)

      capture do
        case form_or_record
        when ActionView::Helpers::FormBuilder
          form_or_record.fields_for(method, proxy) do |f|
            locales_for_localized_field(f, locales, default_locale, &block)
          end
        else
          fields_for(form_or_record, method, proxy) do |f|
            locales_for_localized_field(f, locales, default_locale, &block)
          end
        end
        output_buffer
      end
    end
    
    def localized_text_field(form_or_record, method, field_options = {}, localized_options = {})
      localized_fields_for(form_or_record, method, localized_options) do |f, locale|
        localized_field_options = {}
        field_options.each do |key, value|
          case value
          when Proc
            localized_field_options[key] = value.call(locale)
          else
            localized_field_options[key] = value
          end
        end
        f.text_field(locale, localized_field_options)
      end
    end
    
    def localized_text_area(form_or_record, method, field_options = {}, localized_options = {})
      localized_fields_for(form_or_record, method, localized_options) do |f, locale|
        localized_field_options = {}
        field_options.each do |key, value|
          case value
          when Proc
            localized_field_options[key] = value.call(locale)
          else
            localized_field_options[key] = value
          end
        end
        f.text_area(locale, localized_field_options)
      end
    end

    def locales_for_localized_field(form, locales, default_locale, &block)
      locales.each do |locale|
        display = (locale == default_locale) ? "block" : "none"
        content = block_called_from_erb?(block) ? capture(form, locale, &block) : yield(form, locale)
        concat(content_tag(:div, content, :class => "localized-field localized-field-#{locale}", :style => "display: #{display}"))
      end
    end
  end
end

ActionView::Base.send :include, LocalizedRecord::Helper if defined?(ActionView::Base)