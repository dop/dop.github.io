libs := $(wildcard lib/*.el)
partials := $(wildcard _partials/*)
emacs := /Applications/Emacs.app/Contents/MacOS/Emacs
build := $(emacs) -batch -Q $(foreach lib,$(libs),-l $(lib))

posts := $(wildcard posts/*.org)
pages := $(wildcard pages/*.org)
htmls := index.html $(posts:org=html) $(pages:org=html)

.PHONY: all clean watch serve

all: $(htmls)

%.html: %.org $(partials) $(libs)
	@echo $@ $^
	$(build) -eval "(export-page \"$<\")"

clean:
	rm -f $(htmls)
	rm -f $(htmls:html=html~)

watch:
	fswatch -0 -e .* -Ei '(\.org|Makefile|\.el)$$' . | xargs -0 -I {} make

serve:
	go run serve.go
