module LocalizedRecord
  class InvalidTranslationValue < I18n::MissingTranslationData
    attr_reader :locale, :record, :field, :options
    def initialize(locale, record, field, value, options)
      @record, @field, @value, @locale, @options = record, field, value, locale, options
      super "invalid translation value: #{record.class.to_s}.#{field} (id = #{record.id}) = #{value}", field, {}
      Rails.logger.info(self.message) # XXX - Debug only
    end
  end

  class InvalidTranslationMode < ::ArgumentError
    attr_reader :mode
    def initialize(mode)
      @mode = mode
      super "invalid translation mode: #{mode.inspect}"
    end
  end
end