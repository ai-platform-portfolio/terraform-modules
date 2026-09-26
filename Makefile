PYTHON ?= python3
.PHONY: check test workflow-check
workflow-check:
	@command -v shellcheck >/dev/null
	actionlint

check:
	$(PYTHON) scripts/validate.py
test:
	$(PYTHON) -m unittest discover -s scripts -p 'test_*.py' -v
	$(PYTHON) scripts/validate.py --test
