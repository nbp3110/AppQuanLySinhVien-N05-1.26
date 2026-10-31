# Ảnh minh chứng giao diện (bản trình diễn, Chrome)

Chụp ngày 30/10/2026 từ `flutter run -d chrome --web-port 51238`, chế độ **Khám phá bản trình diễn**.
Dữ liệu là dữ liệu mẫu lưu trên trình duyệt, không ghi Firebase. Không dùng thay cho nghiệm thu
trên Android với Firebase thật.

| Ảnh | Story | Nội dung |
|---|---|---|
| `us01-dang-nhap.png` | US01 | Màn hình đăng nhập và nút vào bản trình diễn |
| `us05-danh-sach.png` | US05 | Danh sách sinh viên, ô tìm kiếm, lọc theo lớp (Tất cả lớp, CNTT01, CNTT02, KT01) |
| `us06-form-loi.png` | US06 | Form Thêm sinh viên: tuổi 20.5 bị từ chối, form giữ nguyên dữ liệu đã nhập |
| `us08-xac-nhan-xoa.png` | US08 | Hộp xác nhận Xóa sinh viên? với hai nút Giữ lại và Xác nhận xóa |
| `us08-chan-xoa.png` | US08 | Sinh viên đã có 2 bản ghi điểm bị chặn xóa, kèm thông báo lý do |
| `us03-us04-ca-nhan.png` | US02, US03, US04 | Hồ sơ cá nhân: tên, email, nút Chỉnh sửa tên và Đăng xuất |

Ảnh chạy với Firebase thật nằm ở [firebase-that/README.md](firebase-that/README.md).

Lưu ý khi dùng trong báo cáo: dữ liệu demo giữ lại trong trình duyệt nên số hồ sơ có thể khác nhau
giữa các ảnh (ví dụ 7 hoặc 8 hồ sơ vì đã xóa SV008 ở một lần chạy trước).
