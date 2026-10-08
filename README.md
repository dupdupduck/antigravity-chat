# ⚡ Antigravity Chat (CLI & Android Mobile App)

Ứng dụng nhắn tin đa năng với kiến trúc Client - Server riêng biệt, hỗ trợ gọi lệnh trực tiếp từ Terminal PC / Termux, ứng dụng đồ họa Android Flutter và tích hợp sẵn trợ lý AI **Antigravity**.

[![Download Android APK](https://img.shields.io/badge/Download-Android%20APK-brightgreen?logo=android)](https://github.com/dupdupduck/antigravity-chat/releases)
[![Build APK](https://github.com/dupdupduck/antigravity-chat/actions/workflows/build-apk.yml/badge.svg)](https://github.com/dupdupduck/antigravity-chat/actions/workflows/build-apk.yml)

### 📲 Tải file APK cho điện thoại Android
Bạn có thể tải file cài đặt `.apk` trực tiếp tại:
👉 **[GitHub Releases - Antigravity Chat APK](https://github.com/dupdupduck/antigravity-chat/releases)**

---

## 🚀 Các tính năng chính

1. **Server Terminal Riêng Biệt (Dedicated Daemon Server)**:
   - Chạy nền dưới dạng daemon với `setsid` và quản lý qua PID.
   - Hỗ trợ đa kết nối, nhiều phòng chat (channels như `#general`, `#dev`), tin nhắn thì thầm riêng tư (`/msg`).
   - Tự động lưu trữ lịch sử tin nhắn và nhật ký (`server.log`, `history.jsonl`).

2. **Trợ lý AI Antigravity tích hợp sẵn (AI Bot)**:
   - Tự động chào mừng khi có thành viên kết nối.
   - Nhận diện các cú pháp `@antigravity`, `@agy`, `@bot`, `/ai`.
   - Phản hồi trạng thái máy chủ, uptime, thời gian hệ thống, tung xúc xắc, kể chuyện vui lập trình, châm ngôn và giải đáp thắc mắc.

3. **Gọi như Terminal PC (Global CLI Tool)**:
   - Đã biên dịch ra binary độc lập và cài đặt sẵn vào PATH: `antigravity-chat` (hoặc tên ngắn gọn: `agchat`).
   - Có thể chạy ở bất cứ đâu trên terminal mà không cần `dart run` hay chuyển thư mục.
   - Hỗ trợ pipe dữ liệu trực tiếp: `echo "Build status: OK" | agchat send -n CI_Bot`.

---

## 🛠️ Hướng dẫn sử dụng

### 1. Quản lý Server

```bash
# Khởi động server chạy nền (daemon)
agchat server start --daemon

# Kiểm tra trạng thái máy chủ (Uptime, số người online, tổng tin nhắn)
agchat status
# hoặc:
agchat server status

# Dừng máy chủ
agchat server stop
```

### 2. Tham gia chat trực tiếp (Interactive Chat Room)

```bash
# Tham gia phòng mặc định (#general) với tên tài khoản của bạn
agchat join

# Tùy chỉnh tên người dùng và phòng chat
agchat join --name Alice --room "#dev"
```

**Các lệnh trong phòng chat:**
- `/help`: Xem hướng dẫn lệnh
- `/users` hoặc `/who`: Danh sách thành viên đang online
- `/join <tên_phòng>`: Đổi sang phòng chat khác (ví dụ: `/join #dev`)
- `/msg <người_nhận> <nội_dung>`: Gửi tin nhắn riêng (whisper)
- `/history [số_lượng]`: Xem lại lịch sử các tin nhắn gần nhất
- `/clear`: Xóa màn hình terminal
- `/quit` hoặc `/exit`: Thoát phiên chat
- `@antigravity <câu hỏi>`: Gọi trợ lý AI Antigravity

### 3. Gửi tin nhắn nhanh từ dòng lệnh (One-shot CLI Send)

```bash
# Gửi tin nhắn nhanh
agchat send -m "Xin chào từ terminal PC!" -n Bob

# Gửi tin nhắn kèm chỉ định phòng
agchat send -m "Đã deploy bản mới lên staging" -n DevOps -r "#dev"

# Pipe dữ liệu từ một lệnh terminal khác vào chat
echo "Log kiểm tra hệ thống: 100% OK" | agchat send -n ServerMonitor
cat /proc/loadavg | agchat send -n CpuWatcher
```

### 4. Kiểm tra danh sách người online & Lịch sử tin nhắn

```bash
# Xem người đang online
agchat users

# Xem 10 tin nhắn gần nhất
agchat history --limit 10
```

---

## 🧪 Kiểm thử & Phân tích mã nguồn

Ứng dụng tuân thủ chuẩn kiến trúc của Dart CLI:

```bash
dart format . --set-exit-if-changed
dart analyze
dart test
```
