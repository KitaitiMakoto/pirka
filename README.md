Pirka
=====

* [Homepage](https://gitlab.com/KitaitiMakoto/pirka)
* [Documentation](http://www.rubydoc.info/gems/pirka)
* [Email](mailto:KitaitiMakoto at gmail.com)

Description
-----------

Pirka highlights source code syntax in EPUB books

Features
--------

* Highlights synatax in EPUB files
* Extracts `<code>` elements from EPUB files and asks you which programing language they are, and then uses them to highlight
* Downloads shared code and language information from Git repository

Examples
--------

### Highlighting source code syntax in EPUB books ###

    $ pirka path/to/book.epub

It's a short cut to:

    $ pirka highlight path/to/book.epub

To highlight books, run `pirka update`(see below for details) just after installation because `pirka highlight` requires library files.

### Detecting source code from EPUB books ###

    $ pirka detect path/to/book.epub
    Detecting code from "Book Title"
    Library file was saved to:
    path/to/library.yaml

`library.yaml` here includes:

* location of `<code>` element(expressed by [EPUB CFI][] but you don't need to undarstand it.)
* `language` field with blank value
* file path in EPUB file(zip archive)
* source code

Example:

      epubcfi(/6/64!/4/2/30/2):              # location
        language:                            # language name. blank at first
        item: OEBPS/text/p-003-003.xhtml     # file path in zip archive
        code: |                              # source code
          f1 = open("|cat", "w")
          f2 = open("|sed 's/a/b/'", "w")
          f1.print "Hello\n"
          f2.print "abc\n"
          f1.close
          f2.close

In Pirka context, the file is called *library*.

`pirka highlight` command determines programming languages of source code according to this file.
Read source code, determine languages, write it at `language` field, remove `code` field, and then
you can highlight the EPUB file by `pirka highlight`.

You also determine languages interactively. Set `-i`(`--interactive`) option:

    $ pirka detect -i path/to/book.epub

[EPUB CFI]: http://www.idpf.org/epub/linking/cfi/

### Updating libraries ###

    $ pirka update

Pirka provides official library files for some EPUB books as Git repository([https://gitlab.com/KitaitiMakoto/pirka-library](https://gitlab.com/KitaitiMakoto/pirka-library)). `pirka update` command fethes the files from the repository and you benefit from it.

Additionally, you can host library files by your own and make Pirka recognizes it by configuration file. See later section for that.

### Listing supported books ###

    $ pirka lib

`pirka lib` command lists books Pirka can highlight with:

* Release Identifier(special identifier for EPUB books)
* location of library file
* title
* some other metadata

### Configuration ###

Pirka can be configured by environment variables, config file and command-line options.

#### Environment variables ####

`XDG_DATA_HOME`
: Affects directory to save library files.
: Library files are saved to `$XDG_DATA_HOME/pirka/local`
: The directory is used to search library, too.
: Default: `$HOME/.local/share`

`XDG_DATA_DIRS`
: Affects directory to save library files.
: You can specify multiple directory by seperating with a colon like `XDG_DATA_DIRS=/dir1:/dir2`.
: `/dir1/pirka/local` and `/dir2/pirka/local` are used to search library, for example.
: Default: `/usr/local/share:/usr/share`

`XDG_CONFIG_HOME`
: Affects directory to search and save config file.
: `$XDG_CONFIG_DIRS/pirka.yaml` is recognized as config file.
: Default: `$HOME/.config`

`XDG_CONFIG_DIRS`
: Affects directory to search config file.
: You can specify multiple directory by seperating with a colon like `XDG_CONFIG_DIRS=/dir1:/dir2`.
: `/dir1/pirka.yaml` and `/dir2/pirka.yaml` are searched as config file.
: Default: `/etc/xdg`

#### Config file ####

Config file is a YAML file. Properties below are recognized:

`data_home`
: Directory to save and search library files.
: Default: `$XDG_CONFIG_HOME/pirka/local`

`additional_directories`
: Directories to search library files.
: Expressed by sequence(array).
: Default: `[]`

`library_repositories`
: Git repository URIs used by `pirka lib` command.
: Expressed by sequence(array).
: Default: `[]`

#### Command-line options ####

You can configure Pirka by `pirka` command's global options:

`-c`, `--config=FILE`
: Path to config file.
: Default: /Users/ikeda/.config/pirka.yaml

`-s`, `--data-home=DIRECTORY`
: Same to config file's `data_home` property.

`-d`, `--directory=DIRECTORY`
: Same to config file's `additional_directories` property.
: Able to multilpe times.

You can also see help by

    $ pirka --help
    Pirka highlights source code syntax in EPUB files
    
    Usage: pirka [global options] [<command>] [options]
    
    Global options:
        -c, --config=FILE                Config file. Defaults to /Users/ikeda/.config/pirka.yaml
        -s, --data-home=DIRECTORY        Directory to *SAVE* library data
        -d, --directory=DIRECTORY        Directory to *SEARCH* library data.
                                         Specify multiple times to add multiple directories.
    
    Commands:
        highlight        Highlights source code in EPUB file
        detect           Detects source code from EPUB file and generate library file
        update           Update library files by remote files
        lib              Show library infomation
    If command is ommitted, highlight is used with no option

Requirements
------------

* Ruby 2.2 or later
* C compiler to compile [Nokogiri][] gem

[Nokogiri]: http://www.nokogiri.org/

Install
-------

    $ gem install pirka

### Make faster ###

By default, Pirka uses [archive-zip][] gem, a pure Ruby implementation, for zip archive but you can make command execution faster by using [Zip/Ruby][] gem, a C implementation. Just install Zip/Ruby:

    $ gem install zipruby

Pirka, actually internally-used [EPUB Parser][], tries to load Zip/Ruby and use it if available.

[archive-zip]: https://github.com/javanthropus/archive-zip
[Zip/Ruby]: https://bitbucket.org/winebarrel/zip-ruby/wiki/Home
[EPUB Parser]: http://www.rubydoc.info/gems/epub-parser/file/docs/Home.markdown

Copyright
---------

Copyright (c) 2017 KITAITI Makoto

See {file:COPYING.txt} for details.
