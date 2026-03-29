
all: calc

calc: parse.f95
	gfortran -std=f95 -o $@ $< -g

parse.f95: parse.y f95.def ../unicc.py
	python3 ../unicc.py f95.def < $< > $@

clean:
	rm -rf calc parse.f95

.PHONY: clean

