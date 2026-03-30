
parse.prg: parse.y foxpro.def ../unicc.py
	python3 ../unicc.py foxpro.def < $< > $@
	unix2dos $@

clean:
	rm -rf parse.prg *.FXP

.PHONY: clean

