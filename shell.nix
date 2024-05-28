{ pkgs ? import <nixpkgs> {} }:

let
  terraform_1_5_7 = pkgs.stdenv.mkDerivation rec {
    pname = "terraform";
    version = "1.5.7";
    src = pkgs.fetchurl {
      url = "https://releases.hashicorp.com/terraform/${version}/terraform_${version}_linux_amd64.zip";
      sha256 = "0b08z9ssnzh3xgz5a7fghl262k3sib4ci0lrmxay4ap55v1ppvf0";
    };

    buildInputs = [ pkgs.unzip ];

    unpackPhase = ''
      mkdir -p $out/bin
      unzip $src -d $out/bin
    '';

    installPhase = ''
      chmod +x $out/bin/terraform
    '';
  };
in
pkgs.mkShell {
  packages = with pkgs; [
    kind
    kubectl
    awscli2
    crossplane-cli
    kubernetes-helm
    terraform_1_5_7
  ];
}
