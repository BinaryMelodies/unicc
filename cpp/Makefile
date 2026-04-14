
all: calc

calc: parse.cc
	g++ -Wall -o $@ $< -g --std=c++17

parse.cc: parse.y ../c/c.def ../unicc.py
	python3 ../unicc.py ../c/c.def $< $@

clean:
	rm -rf calc parse.cc

.PHONY: clean

