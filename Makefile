all:
	# Update the autohandler with version info
	
	rm -f autohandler
	./massage.pl ./autohandler.in ./autohandler
	echo "Done."
