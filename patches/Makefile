apply:
	@(cat `cat series`) | patch -u -E -f -p1 -d ../
	@rm -f unapply
	@touch apply

unapply:
	@(cat `cat series | tac`) | patch -u -p1 -E -f -R -d ../
	@rm -f apply
	@touch unapply
