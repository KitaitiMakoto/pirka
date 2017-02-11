require "base64"
require "yaml"

module Pirka
  class Library
    EXT = ".yaml"

    attr_reader :metadata, :codelist

    # @param [Pathname] directory for library files
    def initialize(directory)
      @directory = directory
      @metadata = {}
      @codelist = {}
    end

    # @todo Better name
    def basename_without_ext
      raise "Release Identifier is not set" unless @metadata["Release Identifier"]
      Base64.urlsafe_encode64(@metadata["Release Identifier"])
    end

    def basename
      basename_without_ext + EXT
    end

    def save(path = nil)
      path = @directory/basename unless path
      path.write(to_yaml)
    end

    # Iterate over codelist in order of EPUB CFI
    # @overload each
    #   @yieldparam [EPUB::CFI] cfi EPUB CFI indicating code element
    #   @yieldparam [String] language Language name
    # @overload each
    #   @return [Enumerator] Enumerator which iterates over cfi and lang
    def each
      sorted_list = @codelist.each_pair.sort_by {|(cfi, lang)| cfi}
      if block_given?
        sorted_list.each do |(cfi, lang)|
          yield cfi, lang
        end
      else
        sorted_list.each
      end
    end

    def to_yaml
      metadata.merge({
        "codelist" => each.with_object({}) {|(cfi, value), list|
          list[cfi.to_fragment] = value
        }
      }).to_yaml
    end
  end
end
