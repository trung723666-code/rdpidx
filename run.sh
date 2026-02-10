#!/usr/bin/env bash
set -e

### CONFIG - ĐIỀN THÔNG TIN CỦA BẠN VÀO ĐÂY ###
NGROK_TOKEN="38WO5iYPn4Hq5A5SUOjtGptsxfE_7jDB4PmSF78GKcAguUo1H" # Token Ngrok bạn đã cung cấp
TELEGRAM_TOKEN="8048006450:AAEcIwETKE8VkDN17GNRu73wifJ-CHPE2bI" # Token Telegram bạn đã cung cấp

WORKDIR="$HOME/windows-idx"
DISK_FILE="$WORKDIR/win11.qcow2"
FLAG_FILE="$WORKDIR/installed.flag"
ISO_FILE="$WORKDIR/win11-gamer.iso"
ISO_URL="https://go.microsoft.com/fwlink/p/?LinkID=2195443"

RAM="8G"
CORES="4"
NGROK_DIR="$HOME/.ngrok"
NGROK_BIN="$NGROK_DIR/ngrok"
NGROK_CFG="$NGROK_DIR/ngrok.yml"
NGROK_LOG="$NGROK_DIR/ngrok.log"

mkdir -p "$WORKDIR"
mkdir -p "$NGROK_DIR"
cd "$WORKDIR"

### HÀM GỬI TELEGRAM (TỰ LẤY CHAT ID NGƯỜI DÙNG) ###
send_tele() {
    # Lấy ID của người nhắn tin gần nhất cho Bot (là chính bạn)
    local cid=$(curl -s "https://api.telegram.org/bot$TELEGRAM_TOKEN/getUpdates" | grep -oP '"id":\K\d+' | head -n 1)
    if [ -z "$cid" ]; then
        echo "❌ Chưa tìm thấy Chat ID. Bạn phải nhấn 'Start' trên Bot Telegram trước!"
    else
        curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage" \
            -d "chat_id=$cid" \
            -d "text=$1" > /dev/null
    fi
}

### 1. CÀI ĐẶT & KHỞI ĐỘNG NGROK ###
if [ ! -f "$NGROK_BIN" ]; then
    curl -sL https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz | tar -xz -C "$NGROK_DIR"
    chmod +x "$NGROK_BIN"
fi

cat > "$NGROK_CFG" <<EOF
version: "2"
authtoken: $NGROK_TOKEN
tunnels:
  rdp:
    proto: tcp
    addr: 3389
EOF

pkill -f "$NGROK_BIN" 2>/dev/null || true
"$NGROK_BIN" start --all --config "$NGROK_CFG" --log=stdout > "$NGROK_LOG" 2>&1 &
sleep 12

RDP_ADDR=$(grep -oE 'tcp://[^ ]+' "$NGROK_LOG" | sed -n '1p')
send_tele "🚀 Máy ảo Windows đang khởi động! 🔗 RDP của bạn: $RDP_ADDR"

### 2. TIẾN TRÌNH DUY TRÌ & CẬP NHẬT MỖI 10 PHÚT ###
(
    while true; do
        # Ghi log để duy trì hoạt động của hệ thống
        echo "[$(date '+%H:%M:%S')] Hệ thống đang hoạt động..." >> "$WORKDIR/update.log"
        sleep 600
    done
) &

### 3. CHẠY MÁY ẢO QEMU ###
[ -f "$DISK_FILE" ] || qemu-img create -f qcow2 "$DISK_FILE" 64G

if [ -f "$FLAG_FILE" ]; then
    echo "✅ Đã cài đặt xong. Đang boot thẳng vào Windows..."
    qemu-system-x86_64 -enable-kvm -cpu host -smp "$CORES" -m "$RAM" \
    -machine q35 -drive file="$DISK_FILE",if=ide,format=qcow2 \
    -netdev user,id=net0,hostfwd=tcp::3389-:3389 -device e1000,netdev=net0 \
    -vnc :0 -usb -device usb-tablet
else
    echo "⚠️ CHẾ ĐỘ CÀI ĐẶT: Đang tải ISO và chuẩn bị máy ảo..."
    [ -f "$ISO_FILE" ] || wget -O "$ISO_FILE" "$ISO_URL"
    
    qemu-system-x86_64 -enable-kvm -cpu host -smp "$CORES" -m "$RAM" \
    -machine q35 -drive file="$DISK_FILE",if=ide,format=qcow2 \
    -cdrom "$ISO_FILE" -boot order=d \
    -netdev user,id=net0,hostfwd=tcp::3389-:3389 -device e1000,netdev=net0 \
    -vnc :0 -usb -device usb-tablet &
    
    QEMU_PID=$!
    
    echo "--------------------------------------------------------"
    echo "👉 SAU KHI CÀI WINDOWS XONG, HÃY GÕ CHỮ: xong"
    echo "👉 Lệnh này sẽ tạo file flag để lần sau không phải cài lại."
    echo "--------------------------------------------------------"
    
    while true; do
        read -p "Trạng thái cài đặt: " STATUS
        if [ "$STATUS" = "xong" ]; then
            touch "$FLAG_FILE"
            send_tele "✅ Chúc mừng! Bạn đã cài đặt thành công và tạo file flag."
            echo "✅ Đã ghi nhận. Hãy khởi động lại script để vào Windows trực tiếp."
            kill $QEMU_PID
            exit 0
        fi
    done
fi
