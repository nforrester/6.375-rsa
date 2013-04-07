all: report.pdf

report.pdf: report.tex
	pdflatex -halt-on-error report.tex
	# run twice to get section numbers and other cross-references right on the first try.
	pdflatex -halt-on-error report.tex

clean:
	rm *.pdf *.toc *.aux *.log
