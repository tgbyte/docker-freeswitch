MODNAME = mod_mosquitto.so
MODOBJ = mosquitto_mosq.o mosquitto_events.o mosquitto_utils.o mosquitto_config.o mosquitto_cli.o mod_mosquitto.o
MODCFLAGS = -Wall -Werror
MODLDFLAGS = -lmosquitto

CC = gcc
CFLAGS = -fPIC -g -ggdb `pkg-config --cflags freeswitch` $(MODCFLAGS)
LDFLAGS = `pkg-config --libs freeswitch` $(MODLDFLAGS)

.PHONY: all
all: $(MODNAME)

$(MODNAME): $(MODOBJ)
	@$(CC) -shared -o $@ $(MODOBJ) $(LDFLAGS)

.c.o: $<
	@$(CC) $(CFLAGS) -o $@ -c $<

.PHONY: clean
clean:
	rm -f $(MODNAME) $(MODOBJ)

.PHONY: install
install: $(MODNAME)
	install -d /usr/lib/freeswitch/mod
	install $(MODNAME) /usr/lib/freeswitch/mod
