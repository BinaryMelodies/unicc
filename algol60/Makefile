
calc: parse.c
	gcc -std=gnu2x $< -o $@ -lalgol -g

parse.c: parse.alg
	marst $< -o $@

parse.alg: parse.y a60.def ../unicc.py
	python3 ../unicc.py a60.def $< $@

calc_alt: parse_alt.c
	gcc -std=gnu2x $< -o $@ -lalgol -g

parse_alt.c: parse_alt.alg
	marst $< -o $@

parse_alt.alg: parse_alt.y a60.def ../unicc.py
	python3 ../unicc.py a60.def $< $@

clean:
	rm -rf calc parse.alg parse.c calc_alt parse_alt.alg parse_alt.c

.PHONY: clean

