PANDOC = pandoc

%.pdf: %.md
	$(PANDOC) $< -o $@

%.html: %.md
	$(PANDOC) $< -o $@

all: check makefile.pdf

check: make_check Makefile1 Makefile2 Makefile3
	sh $< $(word 2, $^)
	sh $< $(word 3, $^)
	sh $< $(word 4, $^)

makefile.md: subs.py makefile.md.in Makefile1 Makefile2 Makefile3 top_rules.mk make.log
	python $< < $(word 2, $^) > $@

clean:
	rm -f *.pdf *.html
	make -f Makefile3 clean

spotless: clean
	rm -f makefile.md
