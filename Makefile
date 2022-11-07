libs := $(wildcard lib/*.el)
partials := $(wildcard _partials/*)
styles := $(wildcard assets/css/*)
bin := /Applications/MacPorts/EmacsMac.app/Contents/MacOS/Emacs
emacs := $(bin) -batch -Q $(foreach lib,$(libs),-l $(lib))

posts := $(wildcard posts/*.org)
pages := $(wildcard pages/*.org)
htmls := $(posts:org=html) $(pages:org=html)

all: index.html $(htmls)

%.html: %.org $(partials) $(styles) $(libs)
	$(emacs) -eval "(export-page \"$<\")"

.PHONEY: clean

clean:
	rm -f $(htmls) $(htmls:html:html~)
	rm -f index.html index.html~
