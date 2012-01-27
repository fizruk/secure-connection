GHC=ghc
GHCFLAGS=--make -threaded

all: client server

client: Client.hs Common.hs
	$(GHC) $(GHCFLAGS) -o $@ $<

server: Server.hs Common.hs
	$(GHC) $(GHCFLAGS) -o $@ $<

.PHONY: clean

certificate:
	openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout privkey.pem -out cert.pem

clean:
	rm -rf *.hi *.o client server
