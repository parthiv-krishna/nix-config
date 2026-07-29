{
  buildbot-nix,
  lib,
  pkgs,
}:
{ primaryRepo, ... }:
let
  effects = import "${buildbot-nix}/herculesCI/effects-lib.nix" { inherit pkgs; };
  knownHosts = pkgs.writeText "github-known-hosts" ''
    github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl
  '';
in
{
  onPush.default.outputs.effects.built-tag = effects.runIf (primaryRepo.branch or null == "main") (
    effects.mkEffect {
      name = "update-built-tag";
      inputs = [
        pkgs.git
        pkgs.nss_wrapper
        pkgs.openssh
      ];
      effectScript = ''
        export USER=buildbot
        export LOGNAME=buildbot
        export NSS_WRAPPER_PASSWD="$HOME/passwd"
        export NSS_WRAPPER_GROUP="$HOME/group"
        export LD_PRELOAD="${pkgs.nss_wrapper}/lib/libnss_wrapper.so"
        printf 'buildbot:x:0:0:Buildbot:%s:/bin/sh\n' "$HOME" > "$NSS_WRAPPER_PASSWD"
        printf 'buildbot:x:0:\n' > "$NSS_WRAPPER_GROUP"
        install -d -m 0700 "$HOME/.ssh"
        install -m 0600 /run/secrets/buildbot-nix/github-nix-config-push-ssh-key "$HOME/.ssh/id_ed25519"
        export GIT_SSH_COMMAND="ssh -i $HOME/.ssh/id_ed25519 -o IdentitiesOnly=yes -o UserKnownHostsFile=${knownHosts}"

        git init repository
        git -C repository remote add origin git@github.com:parthiv-krishna/nix-config.git
        git -C repository fetch --depth=1 origin ${lib.escapeShellArg primaryRepo.rev}
        git -C repository push --force origin FETCH_HEAD:refs/tags/built
      '';
    }
  );
}
