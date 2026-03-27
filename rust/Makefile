
calc: parse.rs
	rustc $^ -o $@

parse.rs: parse.y rust.def ../unicc.py
	python3 ../unicc.py rust.def $< $@

clean:
	rm -rf calc parse.rs

.PHONY:
	clean

