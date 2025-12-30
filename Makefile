# Blog Makefile
# Run targets via nix develop to ensure fly CLI is available

.PHONY: help deploy ssh remote logs status scale regions console db-shell \
        test check format lint dialyzer precommit clean deps compile release

# Default target
help:
	@echo "Blog Makefile"
	@echo ""
	@echo "Deployment:"
	@echo "  make deploy              Deploy to Fly.io (skips depot)"
	@echo "  make deploy-local        Deploy using local Docker builder"
	@echo "  make status              Show app status"
	@echo "  make logs                Tail logs (all regions)"
	@echo "  make logs-REGION         Tail logs for region (e.g., make logs-lhr)"
	@echo ""
	@echo "Remote Access:"
	@echo "  make ssh                 SSH to a random instance"
	@echo "  make ssh-REGION          SSH to instance in region (e.g., make ssh-lhr)"
	@echo "  make remote              Open IEx remote shell"
	@echo "  make remote-REGION       Open IEx remote shell in region"
	@echo "  make console             Select instance interactively"
	@echo "  make db-shell            Open SQLite shell on primary"
	@echo ""
	@echo "Scaling:"
	@echo "  make scale               Show current machine count"
	@echo "  make scale-N             Scale to N machines (e.g., make scale-3)"
	@echo "  make regions             List available regions"
	@echo ""
	@echo "Development:"
	@echo "  make deps                Fetch dependencies"
	@echo "  make compile             Compile the project"
	@echo "  make test                Run tests"
	@echo "  make check               Run format check + credo"
	@echo "  make format              Format code"
	@echo "  make lint                Run credo"
	@echo "  make dialyzer            Run dialyzer"
	@echo "  make precommit           Run full precommit checks"
	@echo "  make clean               Clean build artifacts"
	@echo "  make release             Build release locally"

# ============================================================================
# Deployment
# ============================================================================

deploy:
	nix develop --command flyctl deploy --depot=false --yes

deploy-local:
	nix develop --command flyctl deploy --local-only --yes

status:
	nix develop --command flyctl status

logs:
	nix develop --command flyctl logs

# Region-specific logs: make logs-lhr, make logs-iad, make logs-nrt
logs-%:
	nix develop --command flyctl logs --region $*

# ============================================================================
# Remote Access
# ============================================================================

ssh:
	nix develop --command flyctl ssh console

# Region-specific SSH: make ssh-lhr, make ssh-iad, make ssh-nrt
ssh-%:
	nix develop --command flyctl ssh console --region $*

remote:
	nix develop --command flyctl ssh console --command "/app/bin/blog_web remote"

# Region-specific remote: make remote-lhr, make remote-iad, make remote-nrt
remote-%:
	nix develop --command flyctl ssh console --region $* --command "/app/bin/blog_web remote"

console:
	nix develop --command flyctl ssh console --select

db-shell:
	nix develop --command flyctl ssh console --region lhr --command "sqlite3 /litefs/blog.db"

# ============================================================================
# Scaling
# ============================================================================

scale:
	nix develop --command flyctl scale show

# Scale to N machines: make scale-3
scale-%:
	nix develop --command flyctl scale count $*

regions:
	nix develop --command flyctl platform regions

# ============================================================================
# Development
# ============================================================================

deps:
	mix deps.get

compile:
	mix compile

test:
	mix test

check:
	mix format --check-formatted
	mix credo --strict

format:
	mix format

lint:
	mix credo --strict

dialyzer:
	mix dialyzer

precommit:
	mix precommit

clean:
	mix clean
	rm -rf _build deps

release:
	MIX_ENV=prod mix release blog_web
