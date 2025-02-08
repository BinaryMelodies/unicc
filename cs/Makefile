
calc.exe: Parser.cs
	mcs $^

Parser.cs: Parser.y cs.def ../unicc.py
	python3 ../unicc.py cs.def $< $@

clean:
	rm -rf Parser.exe Parser.cs

.PHONY: clean

