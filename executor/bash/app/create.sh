#!/usr/bin/env bash

carburator print terminal info "Invoking Github git provider..."

# Provisioner defined with a parent command flag
provisioner="$PROVISIONER_NAME"

# Check if cli flag was provided.
if [[ -z $provisioner && -n $GITHUB_PROVISIONER ]]; then
    provisioner="$GITHUB_PROVISIONER"
fi

# ...Or take the first package provider has in it's packages list.
# with service / dns provider we know packages are provisioners.
if [[ -z $provisioner ]]; then
    provisioner="$GIT_PROVIDER_PACKAGES_0_NAME"
fi

# Make sure we have repositories subdir in project dir
repo_path="$PROJECT_PUBLIC/repositories"
mkdir -p "$repo_path"

# Make sure we have project repo toml in repositories dir.
repo_toml="$repo_path/$APP_IDENTIFIER.toml"

# Add config if one is not present already.
if [[ ! -e $repo_toml ]]; then
    # Command argument provided
    if [[ -n $REPOSITORY_PUBLIC ]]; then
        if [[ $REPOSITORY_PUBLIC == true ]]; then
            carburator put toml visibility public -p "$repo_toml"
        else
            carburator put toml visibility private -p "$repo_toml"
        fi
    
    # Ask for preference
    else
        carburator prompt yes-no \
            "Do you want app repository to be private on the git provider?" \
            --yes-val "Yes, make it private" \
            --no-val "No, it should be public" \
            --promote-yes; exitcode=$?

        if [[ $exitcode -eq 0 ]]; then
            carburator put toml visibility private -p "$repo_toml"
        else
            carburator put toml visibility public -p "$repo_toml"
        fi
    fi

fi

# Add required fields for repository toml
carburator put toml name "$APP_IDENTIFIER" -p "$repo_toml"
carburator put toml provisioner "$provisioner" -p "$repo_toml"

description="Automatically created and managed with carburator git provider"
carburator put toml description "$description" -p "$repo_toml"

# Add .gitignore file to app root
{
    echo "# Ignore following dirs and files."
    echo "node_modules/"
    echo "target/"
} > "$APP_PATH/.gitignore"

###
# Run the provisioner and hope it succeeds. Provisioner function has
# retries baked in (if enabled in provisioner.toml).
#
carburator provisioner request \
    git-provider \
    create \
    repository \
    --provider "$GIT_PROVIDER_NAME" \
    --provisioner "$provisioner" || exit 120

# If git repository has not yet been initialized do it now.
if [[ ! -d $APP_PATH/.git ]]; then
    # Jump to app directory before invoking git command
    bash <<EOF
cd "$APP_PATH" || exit 120;
git init
git add .
git commit -m "first commit"
git branch -M main
EOF
fi

# Provisioner has updated our repository toml with repo urls
url=$(carburator get toml url_ssh -p "$repo_toml")

# For non existent or failed ssh url we can try to get the https version.
if [[ -z $url_ssh ]]; then
    url=$(carburator get toml url_https -p "$repo_toml") || exit 120
fi

# Off you go then
git remote add origin "$url" &>/dev/null
git push -u origin main

carburator print terminal success "Github repository for project created."