#!/usr/bin/env bash

carburator fn paint green "Invoking Github git provider..."

###
# Run the provisioner and hope it succeeds. Provisioner function has
# retries baked in (if enabled in provisioner.toml).
#
carburator-rule provisioner request \
    git-provider \
    destroy \
    project-repository \
    --provider "$PROVIDER_NAME" \
    --provisioner "$PROVISIONER_NAME" || exit 120

carburator print terminal info "Destroying Github git provider environment..."

# TODO: keeping these in .env ... better to prefer toml?
rm -f "$PROVIDER_PATH/.env"

carburator print terminal success "Github git provider environment destoryed."
