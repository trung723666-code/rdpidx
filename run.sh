#!/usr/bin/env bash
set -e

### CONFIG ###
TELEGRAM_TOKEN="8048006450:AAEcIwETKE8VkDN17GNRu73wifJ-CHPE2bI"
WORKDIR="$HOME/windows-idx"
DISK_FILE="$WORKDIR/win11.qcow2"
FLAG_FILE="$WORKDIR/installed.flag"
ISO_FILE="$WORKDIR/win11-gamer.iso"
ISO_URL="https://go.microsoft.com/fwlink/p/?LinkID=2195443"

RAM="8G"
CORES="4"
NGROK_LOG="$HOME/.ngrok/ngrok.log"

mkdir -p "$WORKDIR"
cd "$WORKDIR"

### HÀM TELEGRAM (TỰ LẤY ID) ###
send_tele() {
    local cid=$(curl -s "https://api.telegram.org/bot$TELEGRAM_TOKEN/getUpdates" | grep -oP '"id":\K\d+' | head -n 1)
    [ -n "$cid" ] && curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage" -d "chat_id=$cid" -d "text=$1" > /dev/null
}

### 1. KHỞI ĐỘNG NGROK ###
pkill -f ngrok 2>/dev/null || true
"$HOME/.ngrok/ngrok" start --all --config "$HOME/.ngrok/ngrok.yml" --log=stdout > "$NGROK_LOG" 2>&1 &
sleep 12
RDP_ADDR=$(grep -oE 'tcp://[^ ]+' "$NGROK_LOG" | sed -n '2p')
send_tele "🚀 Windows VM Đang chạy! RDP: $RDP_ADDR"

### 2. TIẾN TRÌNH DUY TRÌ 10 PHÚT ###
(
    while true; do
        echo "[$(date '+%H:%M:%S')] Keeping session alive..." >> "$WORKDIR/keepalive.log"
        sleep 600
    done
) &

### 3. CHẠY MÁY ẢO QEMU ###
if [ -f "$FLAG_FILE" ]; then
    echo "✅ Đã tìm thấy file flag. Đang boot thẳng vào Windows..."
    qemu-system-x86_64 -enable-kvm -cpu host -smp "$CORES" -m "$RAM" \
    -machine q35 -drive file="$DISK_FILE",if=ide,format=qcow2 \
    -netdev user,id=net0,hostfwd=tcp::3389-:3389 -device e1000,netdev=net0 \
    -vnc :0 -usb -device usb-tablet
else
    echo "⚠️ ĐANG TRONG CHẾ ĐỘ CÀI ĐẶT"
    [ -f "$ISO_FILE" ] || wget -O "$ISO_FILE" "$ISO_URL"
    
    # Chạy QEMU dưới nền để terminal có thể nhận lệnh "xong"
    qemu-system-x86_64 -enable-kvm -cpu host -smp "$CORES" -m "$RAM" \
    -machine q35 -drive file="$DISK_FILE",if=ide,format=qcow2 \
    -cdrom "$ISO_FILE" -boot order=d \
    -netdev user,id=net0,hostfwd=tcp::3389-:3389 -device e1000,netdev=net0 \
    -vnc :0 -usb -device usb-tablet &
    
    QEMU_PID=$!
    
    echo "-------------------------------------------------------"
    echo "👉 KHI CÀI XONG WINDOWS, HÃY NHẬP CHỮ 'xong' VÀ NHẤN ENTER"
    echo "-------------------------------------------------------"
    
    while true; do
        read -p "Nhập lệnh: " USER_INPUT
        if [ "$USER_INPUT" = "xong" ]; then
            touch "$FLAG_FILE"
            send_tele "✅ Đã tạo file flag thành công! Lần tới sẽ boot thẳng vào ổ cứng."
            echo "✅ Đã lưu trạng thái cài đặt. Hãy khởi động lại workspace."
            kill $QEMU_PID
            exit 0
        fi
    done
fi
