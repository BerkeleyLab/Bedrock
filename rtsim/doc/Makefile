%.pdf: %.eps
	SOURCE_DATE_EPOCH=`git log -n1 --pretty=format:%ct $<` gs -dEPSCrop -sDEVICE=pdfwrite -sOutputFile=$@ -dNOPAUSE -dBATCH -dAutoRotatePages=/None -c .setpdfwrite -f $<

%.pdf: %.tex
	SOURCE_DATE_EPOCH=`git log -n1 --pretty=format:%ct $<` pdftex $<

all: physics.pdf block.pdf block_mode.pdf
# slide7.pdf needs filt_time.pdf and filt_freq.pdf

clean:
	rm -f *.pdf *.log
