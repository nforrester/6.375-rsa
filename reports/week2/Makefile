all: report.pdf

report.pdf: report.tex modMultGraph.png
	pdflatex -halt-on-error report.tex
	# run twice to get section numbers and other cross-references right on the first try.
	pdflatex -halt-on-error report.tex

modMultGraph.png: modMultGraph.dot
	dot -o modMultGraph.png -Tpng modMultGraph.dot

clean:
	rm -f *.pdf *.toc *.aux *.log modMultGraph.png
