
calc: parse.adb
	gnat make -o $@ $< -g

parse.adb: parse.y ada.def ../unicc.py
	python3 ../unicc.py ada.def $< $@

clean:
	rm -rf calc parse.adb

.PHONY: clean

