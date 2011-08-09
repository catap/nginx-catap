default:	build

clean: pre-clean unapply
	@$(RM) -rf objs

pre-clean:
	$(MAKE) -C nginx clean

build: apply
	$(MAKE) -C nginx build

install:
	$(MAKE) -C nginx install

upgrade:
	$(MAKE) -C nginx upgrade

apply:
	$(MAKE) -C patches apply

unapply:
	$(MAKE) -C patches unapply

flat:
	$(MAKE) -C patches flat

test: build
	@TEST_NGINX_BINARY=`pwd`/objs/nginx-catap prove -I `pwd`/tests/lib -r -b --state=all tests modules/ngx_* patches
