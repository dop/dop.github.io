partials := $(wildcard _partials/*)
posts := $(wildcard posts/*.org)
pages := $(wildcard pages/*.org)
htmls := $(posts:org=html) $(pages:org=html)

all: $(htmls) index.html

posts/%.html: posts/%.org $(partials)
	emacs -batch -q -l export.el --eval "(export-final-post \"$<\")"

pages/%.html: pages/%.org $(partials)
	emacs -batch -q -l export.el --eval "(export-final-post \"$<\")"

index.html: index.org $(partials)
	emacs -batch -q -l export.el --eval "(export-file \"$<\" default-styles)"
