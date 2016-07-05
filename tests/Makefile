PORTIA=../portia -libdir ..

.SUFFIXES = .ok .ml .expected

all: Indent_test1.ok Indent_test2.ok Indent_test3.ok test_ctime

Indent_test1.ml: indent_tests.adoc
	$(PORTIA) -syntax ocaml -syntax asciidoc $<

Indent_test2.ml: indent_tests.adoc
	$(PORTIA) -syntax ocaml -syntax asciidoc $<

Indent_test3.ml: indent_tests.adoc
	$(PORTIA) -syntax ocaml -syntax asciidoc $<

Indent_test1.ok: Indent_test1.expected Indent_test1.ml
	diff $^ && touch $@

Indent_test2.ok: Indent_test2.expected Indent_test2.ml
	diff $^ && touch $@

Indent_test3.ok: Indent_test3.expected Indent_test3.ml
	diff $^ && touch $@

# Check we do not alter ctime when we touch a doc and rebuild:
.PHONY: test_ctime
test_ctime: Indent_test1.ml
	@before=$$(stat -f %Dm $<) ;\
	 touch indent_tests.adoc ;\
	 $(MAKE) $< ;\
	 after=$$(stat -f %Dm $<) ;\
	 test $$before -eq $$after

.PHONY: clean
clean:
	@$(RM) *.ok *.ml
