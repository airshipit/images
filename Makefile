TOPTGTS := images lint all docs run_images tests
IMAGES := $(wildcard */Makefile)

$(TOPTGTS): $(IMAGES)
$(IMAGES):
	$(MAKE) -C $(@D) $(MAKECMDGOALS)

.PHONY: $(TOPTGTS) $(IMAGES)
