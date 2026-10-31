# Tài liệu code: module Lớp học, Môn học và Điểm

Phạm vi: US09–US16. Người phụ trách sau khi tách nhóm: Khôi (phần của Khôi và Hiệp trong kế hoạch).
Ngày cập nhật: 31/10/2026. Nhánh: `feature-khoi`.

## 1. Các file chính

| Lớp | File | Vai trò |
|---|---|---|
| Model | `lib/models/class_room.dart` | Lớp học: mã, tên, ngành, khóa. Kiểm tra trước khi ghi. |
| Model | `lib/models/subject.dart` | Môn học: mã, tên, số tín chỉ 1–10. |
| Model | `lib/models/grade.dart` | Điểm: sinh viên, môn, học kỳ, điểm 0–10; `id = sinh viên~môn~học kỳ`. |
| Model | `lib/models/model_validation.dart` | Hàm kiểm tra dùng chung, gồm `semester()` mới: học kỳ dạng `YYYY-1` hoặc `YYYY-2`. |
| Dịch vụ | `lib/services/student_data_service.dart` | `saveGrade` (transaction: kiểm tra sinh viên và môn tồn tại, tăng `gradeCount` khi tạo điểm mới), truy vấn theo lớp/sinh viên. |
| Dịch vụ | `lib/services/firestore_repository.dart` | `create` không ghi đè, `update` không tạo lại bản ghi đã xóa. |
| Trạng thái | `lib/services/project_store.dart` | `saveClass`, `saveSubject`, `saveGrade`; chế độ demo hoặc cloud. |
| Giao diện | `lib/screens/project_workspace.dart` | Trang Lớp học (danh sách, thêm, sửa, "Xem lớp") và trang Sinh viên lọc theo lớp. |
| Giao diện | `lib/screens/subjects_screen.dart` | Danh sách môn, tìm kiếm, thêm môn, trạng thái tải/rỗng/lỗi. |
| Giao diện | `lib/screens/grades_screen.dart` | Chọn sinh viên, bảng điểm, form nhập/cập nhật điểm, trạng thái tải/rỗng/lỗi. |
| Giao diện | `lib/ui/record_form.dart` | Form dùng chung cho lớp học, hiện lỗi khi lưu thất bại. |
| Quyền | `firestore.rules` | Kiểm tra lại dữ liệu và quyền ở phía máy chủ. |

## 2. Ánh xạ Firestore

| Collection | Document ID | Trường |
|---|---|---|
| `classes` | mã lớp | `name`, `major`, `cohort` |
| `subjects` | mã môn | `name`, `credits` (số nguyên) |
| `grades` | `studentId~subjectId~semester` | `studentId`, `subjectId`, `semester`, `score` |

ID nằm ở đường dẫn document, không lưu lặp trong dữ liệu. Document ID của điểm do `Grade.id` sinh ra, nên cùng
sinh viên, môn và học kỳ luôn trỏ vào đúng một bản ghi (lưu lại là cập nhật, không tạo thêm).

## 3. Quy tắc dữ liệu

| Dữ liệu | Quy tắc |
|---|---|
| Mã lớp, mã môn | 1–80 ký tự `A–Z a–z 0–9 _ -`, không đổi sau khi tạo, không trùng |
| Tên lớp, ngành, tên môn | Không trống, tối đa 150 ký tự |
| Khóa học | Không trống, tối đa 30 ký tự |
| Số tín chỉ | Số nguyên 1–10 |
| Học kỳ | Đúng dạng `YYYY-1` hoặc `YYYY-2` (ví dụ `2026-1`); `2026-3`, `2026-0`, `abc` bị từ chối |
| Điểm | Số hữu hạn từ 0 đến 10 (chấp nhận dấu phẩy thập phân khi nhập) |
| Tham chiếu của điểm | Sinh viên và môn học phải tồn tại |

Quy tắc được kiểm tra ba lần: trong form và lớp model (trước khi ghi), trong transaction của
`StudentDataService`, và trong `firestore.rules` (phía máy chủ, kể cả khi client bỏ qua service).

### Kiểm tra học kỳ (thay đổi ngày 31/10/2026)
Trước đây form nhập điểm kiểm tra học kỳ nhưng model và rules chỉ yêu cầu chuỗi hợp lệ kiểu ID, nên học kỳ như
`2026-3` hay `abc` vẫn ghi được qua đường khác. Hiện `Grade` gọi `ModelValidation.semester` (cả khi đọc dữ liệu từ
Firestore), và `firestore.rules` có hàm `semester()` dùng trong `validGrade`. Quy tắc là `^[0-9]{4}-[12]$`, cùng một
mẫu với form nên không cố định năm 2026.

## 4. Luồng và sơ đồ

Các sơ đồ nằm ở [09-class-diagram-va-so-do.md](09-class-diagram-va-so-do.md): tạo lớp (US10), thêm môn học (US14),
lưu điểm (US15), cùng Class Diagram chung.

## 5. Ảnh minh chứng (Firebase thật, 31/10/2026)

Chụp từ bản web đăng nhập vào project `qlsv-n05-phat-khoi`. Bảng đầy đủ ở
[screenshots/firebase-that/README.md](screenshots/firebase-that/README.md).

| Nội dung | Ảnh |
|---|---|
| Danh sách lớp trong app | ![Lớp học](screenshots/firebase-that/03-lop-hoc.png) |
| Sinh viên gắn với lớp | ![Sinh viên gắn lớp](screenshots/firebase-that/04-sinh-vien-gan-lop.png) |
| Danh sách môn học | ![Môn học](screenshots/firebase-that/05-mon-hoc.png) |
| Nhập điểm | ![Nhập điểm](screenshots/firebase-that/06-nhap-diem.png) |
| Firestore: `classes` | ![classes](screenshots/firebase-that/14-console-classes.png) |
| Firestore: `subjects` | ![subjects](screenshots/firebase-that/11-console-subjects.png) |
| Firestore: `grades` | ![grades](screenshots/firebase-that/12-console-grades.png) |

## 6. Kiểm thử theo story

| Story | Test tự động |
|---|---|
| US09 | `test/classes_stories_test.dart` (nhóm US09: hiển thị mã, tên, ngành, khóa, số sinh viên; danh sách rỗng; danh sách theo kịp lớp mới thêm) |
| US10 | `test/classes_stories_test.dart` (nhóm US10: lớp hợp lệ, trùng mã, trường trống, mã có dấu hoặc dấu cách, tên và ngành quá 150 ký tự, khóa quá 30 ký tự); `test/student_data_service_test.dart` (không ghi đè); rules |
| US11 | `test/classes_stories_test.dart` (nhóm US11: mã bị khóa, sửa tên và khóa, sinh viên vẫn gắn lớp, sửa sai giữ dữ liệu cũ, không tạo lớp đã xóa) |
| US12 | `test/classes_stories_test.dart` (nhóm US12: "Xem lớp" chỉ hiện sinh viên của lớp, lớp rỗng báo rõ, đổi lớp cập nhật cả hai lớp); `test/student_data_service_test.dart` (đổi lớp) |
| US13 | `test/subjects_grades_stories_test.dart` (nhóm US13: sắp xếp theo mã, rỗng, tìm không thấy, đang tải, lỗi kèm Thử lại); `test/subjects_grades_screen_test.dart` |
| US14 | `test/subjects_grades_stories_test.dart` (nhóm US14: tín chỉ biên 1 và 10, từ chối 0, 11, -1, chữ, trống; trường bắt buộc; mã sai dạng; tên quá 150; trùng mã không phân biệt hoa thường; Hủy; lỗi từ tầng dữ liệu) |
| US15 | `test/models_test.dart` (học kỳ đúng và sai, đọc dữ liệu sai học kỳ, điểm biên); `test/subjects_grades_stories_test.dart` (nhóm US15: học kỳ, điểm, dấu phẩy, cập nhật một bản ghi, tham chiếu thiếu, lỗi chung, Hủy, thiếu sinh viên hoặc môn); `test/student_data_service_test.dart` (bộ đếm điểm); rules: học kỳ sai bị chặn, hai học kỳ hợp lệ được ghi |
| US16 | `test/subjects_grades_stories_test.dart` (nhóm US16: chỉ điểm của sinh viên đã chọn, học kỳ mới trước, chưa có điểm, điểm mới hiện ngay, đổi sinh viên, đang tải, lỗi kèm Thử lại) |
| Tích hợp | `test/project_modules_integration_test.dart` (thêm môn và nhập điểm qua điều hướng chính, khôi phục sau khi mở lại) |

## 7. Kết quả kiểm tra đã ghi nhận

Ngày 31/10/2026, máy Windows, Flutter 3.47.8, nhánh `feature-khoi`:
- `flutter analyze`: không có vấn đề.
- `flutter test`: 130 test qua (gồm 44 test mới của US09–US16 và phần kiểm tra học kỳ).
- Firestore Emulator (project giả `demo-qlsv`): 12 test qua, 0 lỗi, gồm ca học kỳ sai bị chặn và ca hai học kỳ hợp lệ.

## 8. Hạn chế đã biết

- Xóa lớp, môn và điểm vẫn bị rules khóa (ngoài phạm vi các story hiện tại). Môn học chỉ có chức năng thêm, chưa có sửa.
- Trạng thái đang tải và lỗi của trang Lớp học được xử lý ở mức toàn bộ không gian làm việc (vòng quay chờ, hoặc thông báo lỗi kèm nút Về đăng nhập), chưa có nút Thử lại riêng cho từng trang. Trang môn học và bảng điểm có thông báo lỗi kèm Thử lại.
- Nghiệm thu với Firebase thật mới chạy trên bản web (Chrome); chưa chạy trên Android vì không có thiết bị.
- Dữ liệu điểm cũ trong Firestore (nếu có) có học kỳ sai dạng sẽ bị từ chối khi đọc; hiện dữ liệu trên project `qlsv-n05-phat-khoi` chỉ có học kỳ `2026-1`.
