
all: c java cs pascal basic f77 f95 rust pli algol60 algolw simula algol68 foxpro

clean:
	make -C c clean
	make -C java clean
	make -C cs clean
	make -C pascal clean
	make -C basic clean
	make -C f77 clean
	make -C f95 clean
	make -C rust clean
	make -C pli clean
	make -C algol60 clean
	make -C algolw clean
	make -C simula clean
	make -C algol68 clean
	make -C foxpro clean

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

f95:
	make -C f95

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

algol60:
	make -C algol68 A68C=${A68C}

foxpro:
	make -C foxpro

.PHONY: all clean distclean c java cs pascal basic f77 f95 rust pli algol60 algolw simula algol68 foxpro
