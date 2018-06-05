# frozen_string_literal: true

require "nokogiri"
require "chipmunk/metadata_error"

module Chipmunk
  class AudioMETS

    CATALOG_URL_PREFIX = "mirlyn.lib.umich.edu/Record/"

    def initialize(filehandle)
      @doc = Nokogiri::XML(filehandle)
    end

    def marcxml_url
      if (match = mirlyn_url.match(/(#{CATALOG_URL_PREFIX}\d{9})/))
        "https://#{match[0]}.xml"
      else
        raise MetadataError, "URL #{mirlyn_url} does not match #{CATALOG_URL_PREFIX}RECORDNUM"
      end
    end

    private

    def mirlyn_url
      marc_href_attr = doc.xpath("//mets:mdRef[@MDTYPE='MARC']/@xlink:href").first
      raise MetadataError, "No linked MARC metadata found in mets.xml" unless marc_href_attr
      marc_href_attr.value
    end

    attr_accessor :doc

  end
end
