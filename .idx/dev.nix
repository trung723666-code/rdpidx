# To learn more about how to use Nix to configure your environment
# see: https://developers.google.com/idx/guides/customize-idx-env
{ pkgs, ... }: {
  # Các gói phần mềm cần thiết để chạy QEMU và mạng
  packages = [
    pkgs.qemu_kvm          # Trình giả lập máy ảo
    pkgs.wget              # Tải file ISO
    pkgs.curl              # Gửi thông báo Telegram
    # pkgs.pnt             # <-- LỖI Ở ĐÂY: Gói này không tồn tại, đã loại bỏ.
  ];

  idx = {
    # Các tiện ích mở rộng cho VS Code
    extensions = [
      "ms-python.python"   
    ];

    workspace = {
      # Chạy khi workspace được tạo lần đầu tiên
      onCreate = {
        # Cấp quyền thực thi cho file chạy
        chmod-run = "chmod +x run.sh";
      };
      
      # TỰ ĐỘNG CHẠY mỗi khi bạn mở Workspace
      onStart = {
        run-vps = "bash run.sh";
      };
    };

    previews = {
      enable = true;
      previews = {};
    };
  };
}
