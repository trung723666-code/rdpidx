{ pkgs, ... }: {
  # Cài đặt các gói cần thiết
  packages = [
    pkgs.qemu_kvm
    pkgs.wget
    pkgs.curl
  ];

  idx.workspace = {
    # Tự động chạy khi bạn mở IDX
    onStart = {
      run-vm = "bash run.sh";
    };
  };
}
