{ pkgs, ... }: {
  packages = [
    pkgs.qemu_kvm
    pkgs.wget
    pkgs.curl
  ];

  idx = {
    workspace = {
      onCreate = {
        chmod-run = "chmod +x run.sh";
      };
      onStart = {
        run-vps = "bash run.sh";
      };
    };
  };
}
