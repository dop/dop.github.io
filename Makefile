libs := $(wildcard lib/*.el)
partials := $(wildcard _partials/*)
posts := $(wildcard posts/*.org)
pages := $(wildcard pages/*.org)
htmls := $(posts:org=html) $(pages:org=html)
emacs := emacs -batch -Q $(foreach lib,$(libs),-l $(lib))

all: $(htmls) index.html pages.html

posts/%.html: posts/%.org $(partials) $(libs)
	$(emacs) --eval "(export-page \"$<\")"

pages/%.html: pages/%.org $(partials) $(libs)
	$(emacs) --eval "(export-page \"$<\")"

%.html: %.org $(partials) $(libs)
	$(emacs) --eval "(export-page \"$<\")"

.PHONEY: clean

clean:
	rm -f index.html pages.html
	rm -f pages/*.html
	rm -f posts/*.html
