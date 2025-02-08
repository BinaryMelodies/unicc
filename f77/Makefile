
calc: parse.for
	gfortran -std=legacy -fdec-structure -o $@ $< -g

parse.for: parse.y for.def ../unicc.py
	python3 ../unicc.py for.def < $< > $@

clean:
	rm -rf calc parse.for

.PHONY: clean

