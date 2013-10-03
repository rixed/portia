# vim:filetype=make
OCAMLC     = ocamlfind ocamlc
OCAMLOPT   = ocamlfind ocamlopt
OCAMLDEP   = ocamlfind ocamldep
TEX        = tex
QTEST      = qtest
top_srcdir = .
override OCAMLOPTFLAGS += $(INCS) -w Ael -g -annot -I $(top_srcdir)
override OCAMLFLAGS    += $(INCS) -w Ael -g -annot -I $(top_srcdir)
REQUIRES = batteries dynlink

.PHONY: clean install uninstall reinstall doc loc
.SUFFIXES: .ml .mli .cmo .cmi .cmx .cmxs .tex .dvi .pdf .fw

FW_SOURCES = $(wildcard *.fw)
PROG_SOURCES = config.ml definition.ml parse.ml output.ml main.ml
BACKEND_SOURCES = funnelweb.ml
GEN_SOURCES = $(PROG_SOURCES) $(BACKEND_SOURCES)

all: $(BACKEND_SOURCES:.ml=.cmo)

# dynamically loaded modules must be rebuild after portia.byte has changed
$(BACKEND_SOURCES:.ml=.cmo): portia.byte

doc: portia.pdf portia.html

fwdepend: $(FW_SOURCES)
	@for f in $(FW_SOURCES) ; do \
		sed -n -e 's/^@O@<\([^@]\+\)@>.*$$/\1: '"$$f"'/p' $$f ; \
	done > $@
include fwdepend

$(GEN_SOURCES): $(FW_SOURCES)
	@if test -x portia.byte && test -e funnelweb.cmo ; then \
		echo "Using Portia :-)" ;\
		./portia.byte intro.fw ;\
	 else \
		echo "Using Funnelweb :-(" ;\
		fw intro.fw ;\
	 fi

# We'd be glad to depend on *.ml but ocamldep is so slow...
# Use "make -B depend" when you know you changed dependancies.
depend:
	$(OCAMLDEP) $(SYNTAX) -package "$(REQUIRES)" *.ml > $@
include depend

portia.byte: $(PROG_SOURCES:.ml=.cmo)
	$(OCAMLC)   -o $@ $(SYNTAX) -package "$(REQUIRES)" -linkpkg $(OCAMLFLAGS) $^

portia.opt:  $(PROG_SOURCES:.ml=.cmx)
	$(OCAMLOPT) -o $@ $(SYNTAX) -package "$(REQUIRES)" -linkpkg $(OCAMLOPTFLAGS) $^

.ml.cmo:
	$(OCAMLC) $(SYNTAX) -package "$(REQUIRES)" $(OCAMLFLAGS) -c $<

.mli.cmi:
	$(OCAMLC) $(SYNTAX) -package "$(REQUIRES)" $(OCAMLFLAGS) -c $<

.ml.cmx:
	$(OCAMLOPT) $(SYNTAX) -package "$(REQUIRES)" $(OCAMLOPTFLAGS) -c $<

.ml.cmxs:
	$(OCAMLOPT) $(SYNTAX) -package "$(REQUIRES)" $(OCAMLOPTFLAGS) -o $@ -shared $<

.tex.dvi:
	$(TEX) $<

.dvi.pdf:
	dvipdf $< $@

clean:
	@$(RM) -f *.[aso] *.cmi *.annot *.lis *.tex *.pdf *.dvi *.log *.html $(GEN_SOURCES) $(PROG_SOURCES:.ml=.cmo) all_tests.ml depend fwdepend

distclean: clean
	@$(RM) $(BACKEND_SOURCES:.ml=.cmo) portia.byte

loc: $(GEN_SOURCES)
	@cat $^ | wc -l

# Unit tests

# Tests with qtest

TEST_SOURCES = $(GEN_SOURCES)
all_tests.byte: $(TEST_SOURCES:.ml=.cmo) all_tests.ml
	$(OCAMLC)   -o $@ $(SYNTAX) -package "$(REQUIRES) QTest2Lib" -linkpkg $(OCAMLFLAGS) -w -33 $^

all_tests.ml: $(TEST_SOURCES)
	$(QTEST) --preamble 'open Batteries;;' -o $@ extract $^

check: all_tests.byte
	@echo "Running inline tests"
	@timeout 10s ./$< --shuffle || echo "Fail!"

