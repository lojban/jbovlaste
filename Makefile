all:
	# Update the autohandler with version info
	
	rm -f autohandler
	./massage.pl $(shell svn info ./autohandler.in  | grep Revision | sed 's/.*: //') ./autohandler.in ./autohandler
	echo "Done."
