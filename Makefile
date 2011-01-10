default:	build

clean: pre-clean unapply

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

test: build
	@TEST_NGINX_BINARY=../nginx/objs/nginx-catap prove tests
	make -C modules test