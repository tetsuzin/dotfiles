{ config, pkgs, ... }:

let
  # K8s関連パッケージ
  k8sPackages = with pkgs; [
    kubectl
    kubectx
    krew
  ];

  # krewプラグイン
  krewPlugins = [
    "krew"
    "explore"
    "fuzzy"
    "iexec"
    "images"
    "lineage"
    "ktop"
    "neat"
    "rolesum"
  ];
in
{
  home.packages = k8sPackages;

  home.activation = {
    installKrewPlugins = config.lib.dag.entryAfter [ "writeBoundary" ] ''
      KREW_BIN="${pkgs.krew}/bin/krew"
      for plugin in ${toString krewPlugins}; do
        if ! "$KREW_BIN" list 2>/dev/null | grep -q "^$plugin$"; then
          $DRY_RUN_CMD "$KREW_BIN" install "$plugin"
        fi
      done
    '';
  };
}
