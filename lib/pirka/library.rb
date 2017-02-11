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
      def directories(user = nil)
        [home(user)] +
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

    # @param [Pathname, String, nil] directory for library files. When `nil` passed, default directories are used
    def initialize(directory: nil)
      @directory = directory && Pathname(directory)
      @metadata = {}
      @codelist = {}
    end

    def directories(user = nil)
      return [@directory] if @directory
      self.class.directories(user)
    end

    # @return [String] String that `Release Identifier` property in metadata is encoded based on RFC 4648 "Base 64 Encoding with URL and Filename Safe Alphabet"
    # @see https://tools.ietf.org/html/rfc4648#page-7
    # @todo Better name
    def basename_without_ext
      raise "Release Identifier is not set" unless @metadata["Release Identifier"]
      Base64.urlsafe_encode64(@metadata["Release Identifier"])
    end

    def basename
      basename_without_ext + EXT
    end

    def save(path = nil)
      path = directories.first/basename unless path
      path = Pathname(path) unless path.respond_to? :write
      path.dirname.mkpath unless path.dirname.directory?
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
