# WEKA-styled PDF build for the docs in this repo.
#
# Renders markdown -> WEKA-branded PDF (brand colors + fonts, with code blocks,
# tables, and ASCII diagrams intact) via scripts/md-to-weka-pdf.sh
# (pandoc -> styled HTML -> Chrome headless).
#
# Requires: pandoc, google-chrome/chromium. Best typography with the brand
# fonts installed (IBM Plex Sans, IBM Plex Mono, Onest — OFL); without them the
# layout/colors still render, just with a fallback sans.
#
#   make pdf     # build docs/csi-howto-weka.pdf
#   make clean   # remove generated *-weka.pdf

DOCS   := docs
RENDER := scripts/md-to-weka-pdf.sh

.PHONY: pdf clean
pdf: $(DOCS)/csi-howto-weka.pdf

# Generic rule: docs/NAME.md -> docs/NAME-weka.pdf
$(DOCS)/%-weka.pdf: $(DOCS)/%.md $(DOCS)/weka-doc.css $(RENDER)
	$(RENDER) $< $@

clean:
	rm -f $(DOCS)/*-weka.pdf
