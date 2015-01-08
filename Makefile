all:
	# Update the autohandler with version info
	
	rm -f autohandler
	./massage.pl ./autohandler.in ./autohandler
	[ -f lib/crypt.secret ] || echo $$RANDOM > lib/crypt.secret
	echo "Done."
