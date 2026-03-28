
calc: parse.c
	gcc $< -o $@ -lalgol -I${MARSTPATH} -L${MARSTPATH}/.libs -g

parse.c: parse.alg
	marst $< -o $@

parse.alg: parse.y a60.def ../unicc.py
	python3 ../unicc.py a60.def $< $@

clean:
	rm -rf calc parse.alg parse.c

.PHONY: clean

