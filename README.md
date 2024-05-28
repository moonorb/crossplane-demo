# crossplane-demo
Crossplane requires a Management Kubernetes Cluster. This repository has the steps to deploy a Kind Cluster(with Crosspalane) for managing resources on AWS. Instead of installing kubectl, crossplane-cli and kind we will instead use Nix. While Nix is not a requirement for Crossplane it is the only pre-requisite for this Demo. 


### Install Nix
```
sh <(curl -L https://nixos.org/nix/install) --no-daemon
```

### Prepare Nix shell script

```
cat <<EOF > shell.nix
{ pkgs ? import <nixpkgs> {} }:

let
  terraform_1_5_7 = pkgs.stdenv.mkDerivation rec {
    pname = "terraform";
    version = "1.5.7";
    src = pkgs.fetchurl {
      url = "https://releases.hashicorp.com/terraform/\${version}/terraform_\${version}_linux_amd64.zip";
      sha256 = "0b08z9ssnzh3xgz5a7fghl262k3sib4ci0lrmxay4ap55v1ppvf0";
    };

    buildInputs = [ pkgs.unzip ];

    unpackPhase = ''
      mkdir -p \$out/bin
      unzip \$src -d \$out/bin
    '';

    installPhase = ''
      chmod +x \$out/bin/terraform
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
EOF
```

### Enter nix shell.
```
nix-shell --run $SHELL
```
Within Nix shell kubectl, crossplane and helm commands will be available. This way you don't have to install them on your actual host. 

### Update the credentials file
```
cat <<EOF > credentials/aws-credentials.txt
[default]
aws_access_key_id = AKIAZQ3DPHSQIF4FB22C
aws_secret_access_key = iB5/ppehdnkLT4RMfh+NCT6zFpG8b8UGIXtRJ5xM
EOF
```

### Run installation script
```
./scripts/install-crossplane.nix
```
This script will install a single node Kubernetes Management cluster via Kind as well as Crossplane controllers on this cluster. It takes approximately 2-3 minutes for all the pods to be ready. 

### Check the pods
```
kubectl get po -A

moonorb@crossplane:~/crossplane-demo$ kubectl get po -n crossplane-system
NAME                                                       READY   STATUS    RESTARTS   AGE
crossplane-594f8d6c86-rmh8x                                1/1     Running   0          70s
crossplane-rbac-manager-948695754-z97pv                    1/1     Running   0          70s
provider-aws-s3-6f461b0ba11f-894f47459-55btp               1/1     Running   0          41s
upbound-provider-family-aws-955a69711a10-87fd94fd4-8sskr   1/1     Running   0          45s
```

### Create Composite Resource Definition, Composition and Claim
```
moonorb@crossplane:~/crossplane-demo$ kubectl apply -f apis/definition.yaml 
compositeresourcedefinition.apiextensions.crossplane.io/xobjectstorages.aws.moonorb.cloud created

moonorb@crossplane:~/crossplane-demo$ kubectl apply -f apis/composition.yaml 
composition.apiextensions.crossplane.io/s3bucket.aws.moonorb.cloud created

moonorb@crossplane:~/crossplane-demo$ kubectl apply -f examples/objectstorage-claim.yaml 
objectstorage.aws.moonorb.cloud/myobjectstorage created
```

### Check Crossplane Resources: 
```
watch "crossplane beta trace ObjectStorage myobjectstorage -n test-ns"
NAME                                                  SYNCED   READY   STATUS
ObjectStorage/myobjectstorage (test-ns)               True     True    Available --->Claim 
└─ XObjectStorage/myobjectstorage-2m2rv               True     True    Available --->Composite Resource
   ├─ Bucket/tst-bckt-must-be-uniq                    True     True    Available --->Managed Resource
   └─ BucketPublicAccessBlock/tst-bckt-must-be-uniq   True     True    Available --->Managed Resource

```
READY/True means the resources are provisioned successfully on AWS. 

For more comprehensive Compositions please check this repo: https://github.com/awslabs/crossplane-on-eks.git