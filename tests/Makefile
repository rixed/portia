PORTIA=../portia -libdir ..

.SUFFIXES = .ok .ml .expected

all: test_ctime

Indent_test1.ml: indent_tests.adoc
	$(PORTIA) -syntax ocaml -syntax asciidoc $<

# Check we do not alter ctime when we touch a doc and rebuild:
.PHONY: test_ctime
test_ctime: Indent_test1.ml
	@before=$$(stat --format %D $<) ;\
	 touch indent_tests.adoc ;\
	 $(MAKE) $< ;\
	 after=$$(stat --format %D $<) ;\
	 test "$$before" -eq "$$after"

.PHONY: clean
clean:
	@$(RM) *.ok *.ml
