
calc: parse.c
	gcc -Wall -o $@ $< -g

parse.c: parse.y c.def ../unicc.py
	python3 ../unicc.py c.def $< $@

clean:
	rm -rf calc parse.c

.PHONY: clean

