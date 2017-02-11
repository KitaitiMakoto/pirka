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
    SUBDIR_LENGTH = 4
    XDG_DATA_HOME = Pathname.new(".local/share")
    XDG_DATA_DIRS = [Pathname.new("/usr/local/share"), Pathname.new("/usr/share")]

    @additional_directories = []

    class << self
      attr_accessor :additional_directories

      # @return [Array<Pathname>]
      def directories(user = nil)
        dirs = ENV["XDG_DATA_DIRS"] ?
                 ENV["XDG_DATA_DIRS"].split(":").collect {|dir| Pathname.new(dir)} :
                 XDG_DATA_DIRS
        dirs.unshift data_directory(user)
        @additional_directories + dirs
      end

      # @see https://standards.freedesktop.org/basedir-spec/basedir-spec-latest.html
      def data_directory(user = nil)
        data_home = ENV["XDG_DATA_HOME"] ? Pathname.new(ENV["XDG_DATA_HOME"]) :
                      Pathname.new(Dir.home)/XDG_DATA_HOME
        data_home/"pirka"
      end

      # @param [String] release_identifier
      # @return [Library, nil]
      def find_by_release_identifier(release_identifier)
        lib_path = filepath(release_identifier)
        directories.each do |dir|
          path = dir/lib_path
          return from_file(path) if path.file?
        end
        nil
      end

      # @param [String] release_identifier Release Identifier
      # @return [String] String that `Release Identifier` property in metadata is encoded based on RFC 4648 "Base 64 Encoding with URL and Filename Safe Alphabet"
      # @see https://tools.ietf.org/html/rfc4648#page-7
      # @todo Better name
      def basename_without_ext(release_identifier)
        Base64.urlsafe_encode64(release_identifier)
      end

      def filepath(release_identifier)
        name = basename_without_ext(release_identifier)
        name.insert(SUBDIR_LENGTH, "/") if name.length > SUBDIR_LENGTH
        name + EXT
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

    def data_directory(user = nil)
      return @directory if @directory
      self.class.data_directory(user)
    end

    def filepath
      raise "Release Identifier is not set" unless @metadata["Release Identifier"]
      self.class.filepath(@metadata["Release Identifier"])
    end

    # @param [Pathname, String, nil] path File path to save library data.
    #   When `nil` is passwd, default directory + filepath determined by Release Identifier is used
    # @return [Pathname] File path that library data was saved
    def save(path = nil)
      path = data_directory/filepath unless path
      path = Pathname(path) unless path.respond_to? :write
      path.dirname.mkpath unless path.dirname.directory?
      path.write(to_yaml)
      path
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
