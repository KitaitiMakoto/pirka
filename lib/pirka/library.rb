require "pathname"
require "base64"
require "yaml"
require "epub/parser/cfi"

module Pirka
  # Environment variables affect this class:
  #   XDG_DATA_HOME: Directory to store library files and read. Defaults to $HOME/.local/share
  #   XDG_DATA_DIRS: Directories to search library files. Separated with a colon ':'. Defaults to /usr/local/share:/usr/share
  # 
  # @see https://standards.freedesktop.org/basedir-spec/basedir-spec-latest.html
  class Library
    EXT = ".yaml"
    XDG_DATA_HOME = ".local/share"
    XDG_DATA_DIRS = "/usr/local/share:/usr/share"

    class << self
      attr_accessor :directory

      # @return [Array<Pathname>]
      def directories
        return [@directory] if @directory

        [home] +
          (ENV["XDG_DATA_DIRS"] || XDG_DATA_DIRS).split(":").collect {|dir| Pathname.new(dir)}
      end

      # @see https://standards.freedesktop.org/basedir-spec/basedir-spec-latest.html
      def home(user = nil)
        Pathname.new(ENV["XDG_DATA_HOME"] || Dir.home(user) + XDG_DATA_HOME) + "pirka"
      end

      # @param [String] release_identifier
      # @return [Library, nil]
      def find_by_release_identifier(release_identifier)
        lib_path = basename
        directories.each do |dir|
          path = dir/lib_path
          return from_file(path) if path.file?
        end
        nil
      end

      # @param [Pathname, String] path
      # @return [Library]
      def from_file(path)
        from_hash(YAML.load_file(path.to_s))
      end

      # @param [Hash] h
      # @return [Library]
      def from_hash(h)
        library = new

        h.each_pair do |key, value|
          if key == "codelist"
            value.each_pair do |cfi, data|
              library.codelist[EPUB::Parser::CFI.parse(cfi)] = data
            end
          else
            library.metadata[key] = value
          end
        end

        library
      end
    end

    attr_reader :metadata, :codelist

    # @param [Pathname, nil] directory for library files
    def initialize(directory: nil, path: nil)
      @directory = directory
      @path = path
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

    # @return [String]
    def to_yaml
      metadata.merge({
        "codelist" => each.with_object({}) {|(cfi, value), list|
          list[cfi.to_fragment] = value
        }
      }).to_yaml
    end
  end
end
