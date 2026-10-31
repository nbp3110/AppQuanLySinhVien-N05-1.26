# Ảnh minh chứng: chạy với Firebase thật (G4-03)

Chụp ngày 31/10/2026 từ `flutter run -d chrome --web-port 51238`, đăng nhập bằng tài khoản quản lý
trên project Firebase `qlsv-n05-phat-khoi` (thanh trên cùng của app ghi
"FIREBASE · Dữ liệu dùng chung của nhóm"). Khác với thư mục `../`, dữ liệu ở đây được ghi vào Firestore.

| Ảnh | Story | Nội dung |
|---|---|---|
| `01-dang-nhap-loi.png` | US01 | Đăng nhập sai thông tin: báo lỗi, ở lại màn hình đăng nhập (chụp trước khi bản mới thêm dòng "Chi tiết: mã lỗi") |
| `02-dang-nhap-thanh-cong.png` | US01, US03 | Đăng nhập thành công, vào màn hình Tổng quan; góc dưới trái có tên và vai trò "Người quản lý" |
| `03-lop-hoc.png` | Lớp học | Danh sách 4 lớp đã tạo, mỗi lớp 1 sinh viên |
| `04-sinh-vien-gan-lop.png` | US05, US06, US07 | Danh sách 4 sinh viên, mỗi sinh viên gắn với một lớp (SV01 · MS01 …), có ô tìm kiếm và bộ lọc lớp |
| `05-mon-hoc.png` | Môn học | Danh sách 4 môn học (MH1–MH4, 3 tín chỉ) |
| `06-nhap-diem.png` | Điểm | Hộp thoại nhập điểm: sinh viên SV01, môn MH1, học kỳ 2026-1, điểm 8 |
| `07-chan-xoa-sv-co-diem.png` | US08 | Xóa sinh viên đã có điểm bị chặn: "Không thể xóa Nguyễn Văn A: sinh viên đã có 1 bản ghi điểm." |
| `08-xoa-sv-chua-co-diem.png` | US08 | Xóa sinh viên chưa có điểm thành công: "Đã xóa sinh viên." |
| `09-doi-ten-hien-thi.png` | US04 | Hộp thoại Cập nhật họ tên (chỉ sửa tên hiển thị; email và quyền không đổi) |

Ảnh còn thiếu: Firestore Console (collection `users`, `students` có `gradeCount`, `grades`) và ảnh sau khi
lưu tên mới. Xem hướng dẫn trong tài liệu `../../10-module-sinh-vien-va-tai-khoan.md`, mục 6.
