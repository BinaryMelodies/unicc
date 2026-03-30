
parse.prg: parse.y foxpro.def ../unicc.py
	python3 ../unicc.py foxpro.def < $< > $@
	unix2dos $@

