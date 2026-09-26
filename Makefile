PYTHON ?= python3
.PHONY: check test
check:
	$(PYTHON) scripts/validate.py
test:
	$(PYTHON) scripts/validate.py --test
