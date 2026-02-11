#!/usr/bin/env bash
set -e

### CONFIG ###
TELEGRAM_TOKEN="8048006450:AAEcIwETKE8VkDN17GNRu73wifJ-CHPE2bI"

# Tự động lấy thư mục hiện tại của dự án
PROJECT_DIR=$(pwd)
WORKDIR="$PROJECT_DIR/windows-idx"

DISK_FILE="$WORKDIR/win11.qcow2"
FLAG_FILE="$WORKDIR/installed.flag"
ISO_FILE="$WORKDIR/win11-gamer.iso"
ISO_URL="https://go.microsoft.com/fwlink/p/?LinkID=2195443"

RAM="8G"
CORES="4"

mkdir -p "$WORKDIR"
cd "$WORKDIR"

### HÀM GỬI TELEGRAM ###
send_tele() {
    local cid=$(curl -s "https://api.telegram.org/bot$TELEGRAM_TOKEN/getUpdates" | grep -oP '"id":\K\d+' | head -n 1)
    if [ -n "$cid" ]; then
        curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage" -d "chat_id=$cid" -d "text=$1" > /dev/null
    fi
}

### 1. CÀI ĐẶT & CHẠY BORE ###
if ! command -v bore &> /dev/null; then
    echo "⏳ Đang tải Bore..."
    curl -sL https://github.com/ekzhang/bore/releases/download/v0.5.1/bore-v0.5.1-x86_64-unknown-linux-musl.tar.gz | tar -xz
    chmod +x bore
    mv bore $HOME/bore
fi

BORE_BIN="$HOME/bore"
pkill -f bore 2>/dev/null || true

# Chạy Bore và lưu log vào WORKDIR
$BORE_BIN local 5900 --to bore.pub > "$WORKDIR/vnc.log" 2>&1 &
$BORE_BIN local 3389 --to bore.pub > "$WORKDIR/rdp.log" 2>&1 &

echo "⏳ Đang lấy địa chỉ kết nối..."
sleep 10

VNC_ADDR=$(grep -oE 'bore.pub:[0-9]+' "$WORKDIR/vnc.log" | head -n 1)
RDP_ADDR=$(grep -oE 'bore.pub:[0-9]+' "$WORKDIR/rdp.log" | head -n 1)

MSG="🚀 Windows VM đã sẵn sàng!
🛠️ Setup (VNC): $VNC_ADDR
🔗 Sử dụng (RDP): $RDP_ADDR
(Dùng VNC Viewer để cài đặt Windows trước)"

echo "------------------------------------------"
echo "$MSG"
echo "------------------------------------------"
send_tele "$MSG"

### 2. TIẾN TRÌNH DUY TRÌ (MỖI 10 PHÚT) ###
(
    while true; do
        echo "[$(date '+%H:%M:%S')] Keeping session alive..." >> "$WORKDIR/update.log"
        sleep 600
    done
) &

### 3. CHẠY MÁY ẢO QEMU ###
[ -f "$DISK_FILE" ] || qemu-img create -f qcow2 "$DISK_FILE" 64G

if [ -f "$FLAG_FILE" ]; then
    echo "✅ Boot thẳng vào ổ cứng từ: $DISK_FILE"
    qemu-system-x86_64 -enable-kvm -cpu host -smp "$CORES" -m "$RAM" \
    -machine q35 -drive file="$DISK_FILE",if=ide,format=qcow2 \
    -netdev user,id=net0,hostfwd=tcp::3389-:3389 -device e1000,netdev=net0 \
    -vnc :0 -usb -device usb-tablet
else
    echo "⚠️ CHẾ ĐỘ CÀI ĐẶT"
    [ -f "$ISO_FILE" ] || wget -O "$ISO_FILE" "$ISO_URL"
    
    qemu-system-x86_64 -enable-kvm -cpu host -smp "$CORES" -m "$RAM" \
    -machine q35 -drive file="$DISK_FILE",if=ide,format=qcow2 \
    -cdrom "$ISO_FILE" -boot order=d \
    -netdev user,id=net0,hostfwd=tcp::3389-:3389 -device e1000,netdev=net0 \
    -vnc :0 -usb -device usb-tablet &
    
    QEMU_PID=$!
    while true; do
        read -p "Nhập 'xong' khi cài xong: " CMD
        if [ "$CMD" = "xong" ]; then
            touch "$FLAG_FILE"
            send_tele "✅ Đã tạo file flag tại $WORKDIR"
            kill $QEMU_PID
            exit 0
        fi
    done
fi
