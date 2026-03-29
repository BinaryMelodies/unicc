
calc: parse.c
	gcc -std=gnu2x $< -o $@ -lalgol -g

parse.c: parse.alg
	marst $< -o $@

parse.alg: parse.y a60.def ../unicc.py
	python3 ../unicc.py a60.def $< $@

clean:
	rm -rf calc parse.alg parse.c

.PHONY: clean

