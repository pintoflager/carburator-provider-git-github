#!/usr/bin/env bash

carburator fn paint green "Invoking Github git provider..."

###
# Run the provisioner and hope it succeeds. Provisioner function has
# retries baked in (if enabled in provisioner.toml).
#
carburator provisioner request \
    git-provider \
    destroy \
    repository \
    --provider "$GIT_PROVIDER_NAME" \
    --provisioner "$PROVISIONER_NAME" || exit 120

# TODO: destroy something on the app dir or the whole crap?

carburator log success "Github git provider environment for app destoryed."
