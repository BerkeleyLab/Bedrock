%.pdf: %.eps
	gs -dEPSCrop -sDEVICE=pdfwrite -sOutputFile=$@ -dNOPAUSE -dBATCH -dAutoRotatePages=/None -c .setpdfwrite -f $<

%.pdf: %.tex
	pdftex $<

clean:
	rm -f *.pdf
