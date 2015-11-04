all: notations.html portia.html

portia.html: ../portia/portia.html
	cp -f -l $< $@

notations.html: notations.txt
	asciidoc --theme volnitsky -o $@ $<

