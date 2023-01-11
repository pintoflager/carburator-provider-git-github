#!/usr/bin/env bash

carburator print terminal info "Invoking Github git provider..."

# Provisioner defined with a parent command flag
provisioner="$PROVISIONER_NAME"

# ...Or take the first package provider has in it's packages list.
# with service / dns provider we know packages are provisioners.
if [[ -z $provisioner ]]; then
    provisioner="$PROVIDER_PACKAGES_0_NAME"
fi

# Make sure we have repositories subdir in project dir
repo_path="$PROJECT_PATH/repositories"
mkdir -p "$repo_path"

# Make sure we have project repo toml in repositories dir.
repo_toml="$repo_path/$PROJECT_IDENTIFIER.toml"

# For the first run we have to ask if this repo should be private or public
if [[ ! -e $repo_toml ]]; then
	carburator prompt yes-no \
        "Do you want project repository to be private on the git provider?" \
        --yes-val "Yes, make it private" \
        --no-val "No, it should be public"; exitcode=$?

    if [[ $exitcode -eq 0 ]]; then
		carburator put toml visibility private -p "$repo_toml"
	else
		carburator put toml visibility public -p "$repo_toml"
	fi
fi

# Add required fields for repository toml
carburator put toml name "$PROJECT_IDENTIFIER" -p "$repo_toml"
carburator put toml provisioner "$provisioner" -p "$repo_toml"

description="Automatically created and managed with carburator git provider"
carburator put toml description "$description" -p "$repo_toml"

# Add .gitignore file to project root
{
    echo "# Ignore everything except the given dirs and files."
    echo "*"
    echo
    echo "!.sources"
    echo "!$PROJECT_IDENTIFIER"
    echo "!carburator.toml"
    # echo "!.bins" # Could cause issues if binaries are too big. And .bins dir
    # was meant for testing mainly.
} > "$PROJECT_HOME/.gitignore"

###
# Run the provisioner and hope it succeeds. Provisioner function has
# retries baked in (if enabled in provisioner.toml).
#
carburator-rule provisioner request \
    git-provider \
    create \
    project-repository \
    --provider "$PROVIDER_NAME" \
    --provisioner "$provisioner" || exit 120

# If git repository has not yet been initialized do it now.
if [[ ! -d $PROJECT_HOME/.git ]]; then
    # ATTENTION: we don't have to jump to any dirs as all scripts carburator executes
    # are run from project root dir.
    git init
    git add .
    git commit -m "first commit"
    git branch -M main
fi

# Provisioner has updated our repository toml with repo urls
# TODO: this should be 'carburator-{rule/dev} git ...something'
git remote add origin git@github.com:pintoflager/carburator-provider-git-github.git
git push -u origin main
# TODO:

carburator print terminal success "Github repository for project created."