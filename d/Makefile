
calc: parse.d
	gdc -Wall -o $@ $< -g

parse.d: parse.y d.def ../unicc.py
	python3 ../unicc.py d.def $< $@

clean:
	rm -rf calc parse.d

.PHONY: clean

