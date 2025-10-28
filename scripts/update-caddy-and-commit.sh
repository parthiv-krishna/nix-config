#!/usr/bin/env bash

CADDY_NIX=$1

if [[ ! -f $CADDY_NIX ]]; then
	echo "config file not found: $CADDY_NIX" >&2
	exit 1
fi

# TODO: I think this is good enough, but technically brittle
# find plugins in caddy.nix which contain @
# and find original hash
PLUGINS=$(grep -o '.*@.*' "$CADDY_NIX")
OLD_HASH=$(grep -o 'sha256-[A-Za-z0-9+/=]\+' "$CADDY_NIX")

echo "found plugins:"
echo "$PLUGINS"
echo "old hash: $OLD_HASH"

# minimal nix to build caddy using the pinned nixpkgs from flake.lock
EXPR="
let
  flake = builtins.getFlake \"$(realpath .)\";
  pkgs = flake.inputs.nixpkgs.legacyPackages.\${builtins.currentSystem};
in pkgs.caddy.withPlugins {
  plugins = [
    ${PLUGINS}
  ];
  hash = \"sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=\";
}"

# impure because we are using an unlocked flake
NEW_HASH="$(nix build --impure --expr "$EXPR" 2>&1 | grep -oP 'got:\s+\K(sha256-.+)' | head -n 1)"

if [[ -z $NEW_HASH ]]; then
	echo "failed to determine the new hash from dummy build" >&2
	# rebuild to show output
	nix build --impure --expr "$EXPR" 2>&1
	exit 1
fi

echo "new hash: $NEW_HASH"

if [[ $OLD_HASH == "$NEW_HASH" ]]; then
	echo "hash unchanged"
else
	# sha can contain / so use |
	sed -i "s|$OLD_HASH|$NEW_HASH|" "$CADDY_NIX"
	git add "$CADDY_NIX"
	git commit -m "caddy.nix: update plugins hash

$OLD_HASH -> $NEW_HASH"

	echo "updated hash in $CADDY_NIX"
fi
