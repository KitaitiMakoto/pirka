require "pathname"
require "base64"
require "yaml"
require "epub/cfi"

module Pirka
  # Environment variables affect this class:
  #   XDG_DATA_HOME: Directory to store library files and read. Defaults to $HOME/.local/share
  #   XDG_DATA_DIRS: Directories to search library files. Separated with a colon ':'. Defaults to /usr/local/share:/usr/share
  # 
  # @see https://standards.freedesktop.org/basedir-spec/basedir-spec-latest.html
  class Library
    include GetText

    bindtextdomain TEXT_DOMAIN

    include Enumerable

    DIR_NAME = "pirka/local"
    EXT = ".yaml"
    SUBDIR_LENGTH = 4
    XDG_DATA_HOME = Pathname.new(".local/share")
    DATA_HOME = XDG_DATA_HOME/DIR_NAME
    XDG_DATA_DIRS = [Pathname.new("/usr/local/share"), Pathname.new("/usr/share")]
    DATA_DIRS = XDG_DATA_DIRS.collect {|dir| dir/DIR_NAME}

    @data_home = nil
    @additional_directories = []

    class << self
      attr_accessor :data_home, :additional_directories

      # @return [Array<Pathname>]
      def directories(user = nil)
        data_dirs = ENV["XDG_DATA_DIRS"] ?
                      ENV["XDG_DATA_DIRS"].split(":").collect {|dir| Pathname.new(dir)/DIR_NAME} :
                      DATA_DIRS
        data_home = ENV["XDG_DATA_HOME"] ?
                      Pathname.new(ENV["XDG_DATA_HOME"])/DIR_NAME :
                      Pathname.new(Dir.home(user))/DATA_HOME
        ([@data_home, data_home] + @additional_directories + data_dirs).compact
      end

      # @see https://standards.freedesktop.org/basedir-spec/basedir-spec-latest.html
      def data_directory(user = nil)
        directories.first
      end

      # @param [String] release_identifier
      # @return [Library, nil]
      def find_by_release_identifier(release_identifier)
        lib_path = filename(release_identifier)
        directories.each do |dir|
          path = dir/lib_path
          return load_file(path) if path.file?
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

      def filename(release_identifier)
        name = basename_without_ext(release_identifier)
        name.insert(SUBDIR_LENGTH, "/") if name.length > SUBDIR_LENGTH
        name + EXT
      end

      # @param [Pathname, String] path
      # @return [Library]
      def load_file(path)
        load_hash(YAML.load_file(path.to_s))
      end

      # @param [Hash] h
      # @return [Library]
      def load_hash(h)
        library = new

        h.each_pair do |key, value|
          if key == "codelist"
            value.each_pair do |cfi, data|
              library.codelist[EPUB::CFI.parse(cfi)] = data
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
    def initialize
      @metadata = {}
      @codelist = {}
    end

    def data_directory(user = nil)
      self.class.data_directory(user)
    end

    def filename
      raise _("Release Identifier is not set") unless @metadata["Release Identifier"]
      self.class.filename(@metadata["Release Identifier"])
    end

    # @param [Pathname, String, nil] path File path to save library data.
    #   When `nil` is passwd, default directory + filename determined by Release Identifier is used
    # @return [Pathname] File path that library data was saved
    def save(path = nil)
      path = data_directory/filename unless path
      path = Pathname(path)
      path.dirname.mkpath unless path.dirname.directory?
      path.write to_yaml
      path
    end

    # Iterate over codelist in order of EPUB CFI
    # @overload each
    #   @yieldparam [EPUB::CFI] cfi EPUB CFI indicating code element
    #   @yieldparam [String] language Language name
    # @overload each
    #   @return [Enumerator] Enumerator which iterates over cfi and lang
    def each
      sorted_list = @codelist.each_pair.sort_by {|(cfi, data)| cfi}
      if block_given?
        sorted_list.each do |(cfi, data)|
          yield cfi, data
        end
      else
        sorted_list.each
      end
    end

    # @return [Hash]
    def to_h
      metadata.merge({
        "codelist" => each.with_object({}) {|(cfi, value), list|
          list[cfi.to_s] = value
        }
      })
    end

    # @return [String]
    def to_yaml
      to_h.to_yaml
    end
  end
end
