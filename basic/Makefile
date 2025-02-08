
parse: parse.bas
	fbc $<

parse.bas: parse.y bas.def ../unicc.py
	python3 ../unicc.py bas.def < $< > $@

clean:
	rm -rf parse parse.bas

.PHONY: clean

