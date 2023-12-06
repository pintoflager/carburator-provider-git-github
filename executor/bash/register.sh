#!/usr/bin/env bash

# ATTENTION: Supports only client nodes, pointless to read role from $1
if [[ $1 == "server" ]]; then
    carburator log error \
        "Git providers register only on client nodes. Package configuration error."
    exit 120
fi

# We know we have secrets but this is a good practice anyways.
if carburator has json git_provider.secrets -p .exec.json; then

    # Read secrets from json exec environment line by line
    while read -r secret; do
        # Prompt secret if it doesn't exist yet.
        if ! carburator has secret "$secret" --user root; then
            # ATTENTION: We know only one secret is present. Otherwise
            # prompt texts should be adjusted accordingly.
            carburator log warn \
                "Could not find secret containing Github API token."
            
            carburator prompt secret "Github API key" \
            --name "$secret" \
            --user root || exit 120
        fi
    done < <(carburator get json git_provider.secrets array -p .exec.json)
fi

# Git client is required.
if ! carburator has program git; then
  carburator log error "Please install git before proceeding."
  exit 120
fi

# TODO: untested below. And also not sure if this is even a good idea.
if carburator has program apt; then
    apt install git

elif carburator has program pacman; then
    pacman update
    pacman -S git

elif carburator has program yum; then
    yum install git

elif carburator has program dnf; then
    dnf install git

else
    carburator log error \
        "Unable to detect package manager from client node linux"
    exit 120
fi