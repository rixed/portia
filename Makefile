# vim:filetype=make
PREFIX    ?= /usr
BINDIR    ?= $(PREFIX)/bin/
PLUGINDIR ?= $(PREFIX)/lib/portia

OCAMLC     = ocamlfind ocamlc
OCAMLOPT   = ocamlfind ocamlopt
OCAMLDEP   = ocamlfind ocamldep
QTEST      = qtest
top_srcdir = .
override OCAMLOPTFLAGS += $(INCS) -w +A-e-l-31-33-40-41-42-44-45-70 -g -annot -I $(top_srcdir)
override OCAMLFLAGS    += $(INCS) -w +A-e-l-31-33-40-41-42-44-45-70 -g -annot -I $(top_srcdir)
REQUIRES = batteries dynlink

.PHONY: clean install uninstall reinstall doc loc touch-sources
.SUFFIXES: .ml .mli .cmo .cmi .cmx .cmxs .fw

FW_SOURCES = $(wildcard *.fw) main.fw
LIB_SOURCES = portiaLog.ml portiaConfig.ml portiaDefinition.ml portiaParse.ml
PROG_GEN_SOURCES = $(LIB_SOURCES) output.ml main.ml
PROG_SOURCES = pkgConfig.ml $(PROG_GEN_SOURCES)
BACKEND_SOURCES = funnelweb.ml ocaml.ml c.ml asciidoc.ml
GEN_SOURCES = $(PROG_GEN_SOURCES) $(BACKEND_SOURCES)

all: $(BACKEND_SOURCES:.ml=.cmo) portia portia.cma $(LIB_SOURCES:.ml=.cmi)

# We install only the bytecode version because that's easier to use bytecode
# plugins. Who cares?
portia: portia.byte
	ln -f portia.byte portia

doc: portia.html

portia.html: $(FW_SOURCES)
	asciidoc -o $@ intro.fw
	sed -i.bak -e 's/@@/@/g' $@

# dynamically loaded modules must be rebuild after portia.byte has changed
$(BACKEND_SOURCES:.ml=.cmo): portia.byte

fwdepend: $(FW_SOURCES)
	@for f in $(FW_SOURCES) ; do \
		sed -n -e 's/^@O@<\([^@]\+\)@>.*$$/\1: '"$$f"'/p' $$f ; \
	done > $@
include fwdepend

$(GEN_SOURCES): $(FW_SOURCES)
	@if test -x ./portia && \
		test -e funnelweb.cmo && \
		test -e ocaml.cmo ; then \
		echo "Using Portia to build $@ :-)" ;\
		./portia -libdir . -syntax ocaml -syntax funnelweb intro.fw ;\
	 else \
		echo "Using Funnelweb to build $@ :-(" ;\
		fw intro.fw ;\
	 fi

# We'd be glad to depend on *.ml but ocamldep is so slow...
# Use "make -B depend" when you know you changed dependencies.
depend:
	$(MAKE) $(GEN_SOURCES)
	$(OCAMLDEP) $(SYNTAX) -package "$(REQUIRES)" *.ml > $@
include depend

portia.byte: $(PROG_SOURCES:.ml=.cmo)
	$(OCAMLC)   -o $@ $(SYNTAX) -package "$(REQUIRES)" -linkpkg $(OCAMLFLAGS) $^

portia.opt:  $(PROG_SOURCES:.ml=.cmx)
	$(OCAMLOPT) -o $@ $(SYNTAX) -package "$(REQUIRES)" -linkpkg $(OCAMLOPTFLAGS) $^

pkgConfig.ml:
	echo 'let plugindir = "$(PLUGINDIR)"' > $@

%.cmo %.cmi &: %.ml
	$(OCAMLC) $(SYNTAX) -package "$(REQUIRES)" $(OCAMLFLAGS) -c $<

%.cmx: %.ml
	$(OCAMLOPT) $(SYNTAX) -package "$(REQUIRES)" $(OCAMLOPTFLAGS) -c $<

%.cmxs: %.ml
	$(OCAMLOPT) $(SYNTAX) -package "$(REQUIRES)" $(OCAMLOPTFLAGS) -o $@ -shared $<

portia.cma: $(LIB_SOURCES:.ml=.cmo) $(LIB_SOURCES:.ml=.cmi)
	$(OCAMLC) $(SYNTAX) -package "$(REQUIRES)" -a -o $@ -custom -linkpkg $(OCAMLFLAGS) $(LIB_SOURCES:.ml=.cmo)

clean:
	@$(RM) *.[aso] *.cmi *.cmt *.annot *.lis *.html $(PROG_SOURCES:.ml=.cmo) \
	  all_tests.ml
	@$(MAKE) -C tests clean

distclean: clean
	@$(RM) $(BACKEND_SOURCES:.ml=.cmo) portia.byte portia.opt portia.cma portia all_tests.byte

cleansources:
	@$(RM) $(GEN_SOURCES) depend fwdepend

loc: $(GEN_SOURCES)
	@cat $^ | wc -l

install: all
	ocamlfind install portia META portia portia.cma $(LIB_SOURCES:.ml=.cmi) $(BACKEND_SOURCES:.ml=.cmo)

uninstall:
	ocamlfind remove portia

reinstall: uninstall install

# After `git clone` the timestamps of the generated files might not be newer than their sources:
touch-sources:
	@sleep 1
	@touch $(GEN_SOURCES) depend fwdepend

# Unit tests

# Tests with qtest

TEST_SOURCES = $(filter-out main.ml,$(GEN_SOURCES))
all_tests.byte: $(TEST_SOURCES:.ml=.cmo) all_tests.ml
	$(OCAMLC)   -o $@ $(SYNTAX) -package "$(REQUIRES) qcheck" -linkpkg $(OCAMLFLAGS) -w -33 $^

all_tests.ml: $(TEST_SOURCES)
	$(QTEST) --shuffle --preamble 'open Batteries;;' -o $@ extract $^

check: all_tests.byte
	@echo "Running inline tests"
	@timeout 10s ./$< || echo "Fail!"
	@$(MAKE) -C tests || echo "Fail!"
