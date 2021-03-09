GIT_REPO_ROOT          := $(shell git rev-parse --show-toplevel)

.DEFAULT_GOAL := help
.PHONY: help
help:  ## このドキュメントを表示します。
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-40s\033[0m %s\n", $$1, $$2}'

.PHONY: lock
lock:  ## lock ファイルを生成／更新します。
	vscodeenv freeze | tee ./vscodeenv.lock.sh
