
all: calc calc_norec

calc: parse.for
	gfortran -std=legacy -fdec-structure -o $@ $< -g

parse.for: parse.y for.def ../unicc.py
	python3 ../unicc.py for.def < $< > $@

calc_norec: parse_norec.for
	gfortran -std=legacy -o $@ $< -g

parse_norec.for: parse_norec.y for.def ../unicc.py
	python3 ../unicc.py for.def < $< > $@

clean:
	rm -rf calc parse.for calc_norec parse_norec.for

.PHONY: clean

