all: liblbuild_util.so

liblbuild_util.so: util.c
	$(CC) $(CFLAGS) -fPIC -shared util.c -o liblbuild_util.so

$(DESTDIR)/usr/lib/liblbuild_util.so: liblbuild_util.so
	install -D -m 0744 $< $@

$(DESTDIR)/usr/bin/lbuild: lbuild.lua
	install -D -m 0755 $< $@

$(DESTDIR)/usr/share/lua/5.1/lbuild/%.lua: lbuild/%.lua
	install -D -m 0744 $< $@

install: $(DESTDIR)/usr/lib/liblbuild_util.so $(DESTDIR)/usr/bin/lbuild \
	$(foreach l,$(shell ls lbuild),$(DESTDIR)/usr/share/lua/5.1/lbuild/$(l))

clean:
	rm -f *.so example/*.o
