
calc.class: Parser.java
	javac $^

Parser.java: Parser.y java.def ../unicc.py
	python3 ../unicc.py java.def $< $@

clean:
	rm -rf *.class Parser.java

.PHONY: clean

