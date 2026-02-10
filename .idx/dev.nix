# To learn more about how to use Nix to configure your environment
# see: https://developers.google.com/idx/guides/customize-idx-env
{ pkgs, ... }: {
  # Các gói phần mềm cần thiết để chạy QEMU và mạng
  packages = [
    pkgs.qemu_kvm          # Trình giả lập máy ảo hiệu suất cao
    pkgs.wget              # Tải file ISO
    pkgs.curl              # Gửi thông báo Telegram và gọi API
    pkgs.pnt               # Tiện ích mạng bổ trợ
  ];

  # Cấu hình biến môi trường
  env = {
    # Bạn có thể thêm các biến môi trường tại đây nếu cần
  };

  idx = {
    # Các tiện ích mở rộng hữu ích cho lập trình viên
    extensions = [
      "ms-python.python"   # Hỗ trợ Python (vì bạn là Python developer)
    ];

    workspace = {
      # Chạy khi workspace được tạo lần đầu tiên
      onCreate = {
        # Cấp quyền thực thi cho file chạy
        chmod-run = "chmod +x run.sh";
      };
      
      # TỰ ĐỘNG CHẠY mỗi khi bạn mở Workspace (giúp bạn không cần gõ lệnh thủ công)
      onStart = {
        run-vps = "bash run.sh";
      };
    };

    # Cấu hình xem trước (không bắt buộc cho QEMU nhưng để IDX hoạt động ổn định)
    previews = {
      enable = true;
      previews = {
        # Bạn có thể cấu hình preview web tại đây nếu cần
      };
    };
  };
}
