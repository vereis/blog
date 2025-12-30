.PHONY: help deploy logs logs-% ssh ssh-% remote remote-% precommit

help:
	@echo "make deploy        Deploy to Fly.io"
	@echo "make logs          Tail logs (all regions)"
	@echo "make logs-REGION   Tail logs for region (e.g., make logs-lhr)"
	@echo "make ssh           SSH to instance"
	@echo "make ssh-REGION    SSH to instance in region"
	@echo "make remote        Open IEx remote shell"
	@echo "make remote-REGION Open IEx remote shell in region"
	@echo "make precommit     Run full precommit checks"

deploy:
	flyctl deploy --depot=false --yes

logs:
	flyctl logs

logs-%:
	flyctl logs --region $*

ssh:
	flyctl ssh console

ssh-%:
	flyctl ssh console --region $*

remote:
	flyctl ssh console --command "/app/bin/blog_web remote"

remote-%:
	flyctl ssh console --region $* --command "/app/bin/blog_web remote"

precommit:
	mix precommit
