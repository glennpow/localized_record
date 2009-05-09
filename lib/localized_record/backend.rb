require 'libxml'

module LocalizedRecord
  mattr_accessor :mode, :supported_locales
  
  self.mode = :tsv
  self.supported_locales = [ I18n.default_locale.to_s, 'es' ]
  
  def supported_modes
    [ :tsv, :tmx ]
  end

  def self.localized?(value, mode = nil)
    mode ||= LocalizedRecord.mode
    
    case mode
    when :tsv
      value =~ /\t/
      
    when :tmx
      value =~ /^<\?xml version="[^"]+" \?>[ \n\r]*<tmx version="[^"]+">/

    else
      raise InvalidTranslationMode.new(mode)
    end
  end

  def self.parse(value, mode = nil)
    mode ||= LocalizedRecord.mode

    case mode
    when :tsv
      translations = Hash[*value.split("\t")]
      
    when :tmx
      translations = {}
      if defined?(LibXML)
        parser = LibXML::Parser.new
        parser.string = value
        doc = parser.parse
        tuvs = doc.find("//tu/tuv")
        tuvs.each do |tuv|
          if seg = tuv.find_first("/seg")
            translations[tuv.attributes["xml:lang"]] = seg.content
          end
        end
      end
      translations

    else
      raise InvalidTranslationMode.new(mode)
    end
  end
  
  def self.compile(translations, mode = nil)
    mode ||= LocalizedRecord.mode

    case mode
    when :tsv
      translations.inject('') { |output, (locale, value)| "#{output}#{output.blank? ? "" : "\t"}#{locale}\t#{value}" }
      
    when :tmx
      # TODO

    else
      raise InvalidTranslationMode.new(mode)
    end
  end
end
