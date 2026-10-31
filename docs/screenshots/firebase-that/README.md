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

Ảnh Firebase Console (project `qlsv-n05-phat-khoi`, Firestore Database, tab Data):

| Ảnh | Nội dung |
|---|---|
| `10-console-users.png` | Collection `users`: 2 document có ID là UID của tài khoản; hồ sơ có `displayName`, `email`, `role: "manager"` |
| `11-console-subjects.png` | Collection `subjects`: MH1–MH4, document MH1 có `name` và `credits: 3` |
| `12-console-grades.png` | Collection `grades`: ID dạng `SV01~MH1~2026-1`, có `score: 8`, `semester`, `studentId`, `subjectId` |
| `13-console-students-gradecount.png` | Collection `students`: SV01 có `gradeCount: 1` (bộ đếm điểm dùng để chặn xóa, US08), cùng `age`, `classId`, `email`, `major`, `name` |
| `14-console-classes.png` | Collection `classes`: MS01–MS04, document MS01 có `cohort: "K18"`, `major`, `name` |
| `15-console-rules.png` | Tab Rules của Firestore: rules đã publish (có hai phiên bản, bản mới nhất ngày 30/10), thấy hàm `manager()` kiểm tra vai trò |
| `16-console-authentication.png` | Authentication → Users: 2 tài khoản email/mật khẩu (24100212 và 24100066), đã đăng nhập ngày 31/10 |
| `17-doi-ten-da-luu.png` | Sau khi lưu: "Nguyen Ba Phat" hiện ở Hồ sơ của bạn và góc dưới trái (US04) |
