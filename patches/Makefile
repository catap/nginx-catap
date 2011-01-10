apply:
	@(cat `cat series`) | patch -p1 -d ../
	@rm -f unapply
	@touch apply

unapply:
	@(cat `cat series`) | patch -p1 -R -d ../
	@rm -f apply
	@touch unapply
