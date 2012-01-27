GHC=ghc
GHCFLAGS=--make -threaded

all: client server

client: Client.hs Common.hs
	$(GHC) $(GHCFLAGS) -o $@ $<

server: Server.hs Common.hs
	$(GHC) $(GHCFLAGS) -o $@ $<

.PHONY: clean

clean:
	rm -rf *.hi *.o client server
