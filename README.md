Pirka
=====

* [Homepage](http://www.rubydoc.info/gems/pirka)
* [Documentation](http://rubydoc.info/gems/pirka/frames)
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

Pirka provides official library files for some EPUB books as Git repository((https://gitlab.com/KitaitiMakoto/pirka-library)[https://gitlab.com/KitaitiMakoto/pirka-library]). `pirka update` command fethes the files from the repository and you benefit from it.

Additionally, you can host library files by your own and make Pirka recognizes it by configuration file. See later section for that.

### Listing supported books ###

    $ pirka lib

`pirka lib` command lists books Pirka can highlight with:

* Release Identifier(special identifier for EPUB books)
* location of library file
* title
* some other metadata

### Configuration ###

Requirements
------------

* Ruby 2.2 or later
* C compiler to compile [Nokogiri][] gem

[Nokogiri]: http://www.nokogiri.org/

Install
-------

    $ gem install pirka

Synopsis
--------

    $ pirka

### Make faster ###


Copyright
---------

Copyright (c) 2017 KITAITI Makoto

See {file:COPYING.txt} for details.
