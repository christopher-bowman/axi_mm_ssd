
#
# Copyright (C) 2010 Christopher R. Bowman.  All rights reserved
# contact: <my initials>@ChrisBowman.com
#
# This make file builds the project documentation
#

all: doc

help:
	@echo "targets:"
	@echo "========"
	@echo "doc               build the project specification pdf"
	@echo "view              run evince on the specification pdf"
	@echo "specification.ps  bulid a postscript version of the specification"

doc: specification.pdf

%.toc: %.tex
	latex $<

%.lot: %.tex
	latex $<

#%.dvi: %.lot %.toc %.tex
#	@echo "built .lot and .toc"
#	latex $<

%.dvi: %.tex			# override the built in
	latex $<
	latex $<

%.pdf: %.dvi
	dvipdf $<

%.ps: %.dvi
	dvips $<

view: doc
	evince specification.pdf

clean: 
	rm -rf specification.dvi specification.toc specification.lot specification.log specification.aux specification.pdf specification.ps specification.out

.PHONY: doc
