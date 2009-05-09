module LocalizedRecord
  module Helper
    def localized_select(options = {})
      locales = (options.delete(:locales) || LocalizedRecord.supported_locales).map(&:to_s)
      default_locale = (options.delete(:default_locale) || I18n.default_locale).to_s

      select_options = options.merge(:onchange => "$$('.localized-field').invoke('hide'); $$('.localized-field-' + this.options[this.selectedIndex].value).invoke('show')")
      select_tag("localized_select", options_for_select(locales.map { |locale| [ locale, locale ] }, default_locale), select_options)
    end

    def localized_text_field(form_or_record, method, options = {})
      locales = (options.delete(:locales) || LocalizedRecord.supported_locales).map(&:to_s)
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
            locales.each do |locale|
              display = (locale == default_locale) ? "block" : "none"
              text_field_options = {}
              options.each do |key, value|
                if value.is_a?(Proc)
                  text_field_options[key] = value.call(locale)
                else
                  text_field_options[key] = value
                end
              end
              concat(content_tag(:div, f.text_field(locale, text_field_options), :class => "localized-field localized-field-#{locale}", :style => "display: #{display}"))
            end
          end
        else
          fields_for(form_or_record, method, proxy) do |f|
            locales.each do |locale|
              display = (locale == default_locale) ? "block" : "none"
              text_field_options = {}
              options.each do |key, value|
                if value.is_a?(Proc)
                  text_field_options[key] = value.call(locale)
                else
                  text_field_options[key] = value
                end
              end
              concat(content_tag(:div, f.text_field(locale, text_field_options), :class => "localized-field localized-field-#{locale}", :style => "display: #{display}"))
            end
          end
        end
        output_buffer
      end
    end
  end
end

ActionView::Base.send :include, LocalizedRecord::Helper if defined?(ActionView::Base)