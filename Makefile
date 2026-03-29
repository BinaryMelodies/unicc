
all: c java cs pascal basic f77 rust pli algol60 algolw simula

clean:
	make -C c clean
	make -C java clean
	make -C cs clean
	make -C pascal clean
	make -C basic clean
	make -C f77 clean
	make -C rust clean
	make -C pli clean
	make -C algol60 clean
	make -C algolw clean
	make -C simula clean

distclean: clean
	rm -rf *~ */*~

c:
	make -C c

java:
	make -C java

cs:
	make -C cs

pascal:
	make -C pascal

basic:
	make -C basic

f77:
	make -C f77

rust:
	make -C rust

pli:
	make -C pli PLIPATH=${PLIPATH}

algol60:
	make -C algol60

algolw:
	make -C algolw

simula:
	make -C simula

.PHONY: all clean distclean c java cs pascal basic f77 rust pli algol60 algolw simula
