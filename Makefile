all: notations.html index.html

index.html: ../portia/portia.html
	cp -f $< $@

notations.html: notations.txt
	asciidoc --theme volnitsky -o $@ $<

