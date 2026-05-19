.PHONY: spec docs examples

all: fmt lint docs spec examples

fmt:
	crystal tool format

spec:
	crystal spec -v

AMEBA=./lib/ameba/bin/ameba

$(AMEBA): $(AMEBA).cr
	crystal build -o $@ $(AMEBA).cr

lint: $(AMEBA)
	$(AMEBA)

docs:
	crystal docs

examples:
	for f in examples/*.cr; do crystal run "$$f"; done

clean:
	rm -rf docs
