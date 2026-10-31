# Ma trận kiểm thử và rà soát nền G1-05

Ngày rà soát: 27/10/2026. Ma trận này bổ sung kế hoạch kiểm thử và ghi nhận phạm vi test nền; không có nghĩa 16 UI stories đã triển khai.

## Ma trận 16 stories

| Story / người làm | Trường hợp đúng | Trường hợp sai | Nền hiện có / còn thiếu |
|---|---|---|---|
| US01 — Bắc | Manager đăng nhập đúng, hồ sơ manager tải, vào trang chính | Sai mật khẩu, thiếu profile/role, lỗi mạng; không vào vùng quản lý | Rules kiểm tra quyền Firestore; chưa có AuthService/UI test đăng nhập |
| US02 — Bắc | Đăng xuất về login, stream dừng, Back không mở lại dữ liệu | Không được lộ dữ liệu phiên cũ khi subscription còn hoạt động | Chưa có logout/navigation/subscription test |
| US03 — Bắc | Hiện displayName/email từ users/{uid}, có loading/error | Không hiện mật khẩu; không đọc hồ sơ người khác; thiếu hồ sơ báo lỗi | Model/rules có test một phần; chưa có profile UI test |
| US04 — Bắc | Tên sau trim hợp lệ, lưu và tải lại; chỉ sửa displayName của mình | Rỗng, >150 ký tự, sửa email/role/uid hoặc hồ sơ khác | Rules test sửa tên và chặn email/role; thiếu biên 150, trim, UI |
| US05 — Phát | Danh sách mã/tên/lớp; loading/rỗng/lỗi; nhận cập nhật | Không hiện dữ liệu sai hoặc báo thành công giả | FakeFirestore test watchAll/lọc lớp; thiếu UI/loading/error/stream-update |
| US06 — Phát | Tạo SV mới, đọc lại; lớp tồn tại hoặc null; email hợp lệ/rỗng | Trùng mã, tên/ngành trống, tuổi ngoài 1–120/không nguyên, email sai, lớp thiếu | Test duplicate/reference; model/rules kiểm tra một phần; thiếu biên tuổi/email và CRUD cloud |
| US07 — Phát | Sửa trường cho phép, giữ mã, đọc lại đúng | Mã không đổi; invalid data bị chặn; update ID đã xóa không tạo mới | Repository test update/readback; thiếu mã bất biến, deleted ID, UI báo lỗi |
| US08 — Phát | Hủy xác nhận giữ nguyên; xóa khi không có điểm; danh sách cập nhật | Có điểm thì chặn; xung đột tạo điểm/xóa vẫn giữ invariant | Delete bị rules chặn có test; workflow chưa làm, chưa mở quyền |
| US09 — Khôi | Danh sách lớp mã/tên/ngành/khóa; loading/rỗng/lỗi; cập nhật | Lỗi tải không hiện danh sách giả | Repository watchAll có nền; thiếu UI/loading/error/stream-update |
| US10 — Khôi | Tạo lớp mã mới và tải lại đúng | Trùng mã; tên/ngành/khóa trống hoặc vượt giới hạn | Duplicate/rules một phần; thiếu biên và UI |
| US11 — Khôi | Sửa tên/ngành/khóa, giữ mã; SV vẫn liên kết | Dữ liệu sai hoặc update lớp thiếu không tạo mới | Repository update không tạo mới test tổng quát; thiếu liên kết/biên UI |
| US12 — Khôi | Chỉ SV cùng classId; lớp rỗng báo rõ; đổi lớp phản ánh | Không hiện SV lớp khác hoặc dữ liệu cũ sau đổi lớp | FakeFirestore lọc classId; thiếu empty-state và stream-update |
| US13 — Hiệp | Danh sách môn mã/tên/tín chỉ; loading/rỗng/lỗi | Lỗi tải không dùng dữ liệu giả | Repository watchAll nền tổng quát; chưa có UI test |
| US14 — Hiệp | Tạo môn hợp lệ, tải lại | Trùng mã; tên trống/>150; tín chỉ không nguyên/ngoài 1–10 | Model/rules một phần; thiếu duplicate Subject, biên credits và UI |
| US15 — Hiệp | Lưu lần đầu; cùng bộ SV/môn/kỳ cập nhật một record; kỳ khác lưu riêng | Thiếu SV/môn, kỳ sai, điểm NaN/vô cực/<0/>10 | FakeFirestore upsert/reference; model test điểm biên; kỳ hiện chỉ là mã tổng quát, cần validator YYYY-1/2 |
| US16 — Hiệp | Chỉ bảng điểm SV đã chọn; môn/kỳ/điểm; loading/rỗng/lỗi; cập nhật sau US15 | Không lẫn SV khác hoặc giữ dữ liệu cũ khi đổi lựa chọn | FakeFirestore lọc studentId; thiếu stream-update và UI states |

## Dữ liệu mẫu thống nhất

Chỉ dùng dữ liệu giả cho unit test, emulator và ảnh demo. Không lưu mật khẩu/dữ liệu cá nhân; không seed tự động khi mở app; không nạp fixture vào Firebase cloud chung.

| Collection | ID | Dữ liệu |
|---|---|---|
| users | `manager-test-01` | email `manager.test@example.invalid`, displayName `Quản lý mẫu`, role `manager` |
| classes | `CNTT01` | Công nghệ thông tin 01, CNTT, K17 |
| classes | `KT01` | Kế toán 01, Kế toán, K17 |
| students | `SV001` | Sinh viên Mẫu 01, CNTT, tuổi 21, email `sv001@example.invalid`, classId `CNTT01` |
| students | `SV002` | Sinh viên Mẫu 02, CNTT, tuổi 20, email rỗng, classId null |
| subjects | `MOB01` | Lập trình di động, 3 tín chỉ |
| grades | `SV001~MOB01~2026-1` | SV001, MOB01, học kỳ 2026-1, điểm 8.5 |

Ca sai: mã trùng SV001; tuổi 0/121/21.5; email `khong-hop-le`; classId NOCLASS; tên rỗng; tín chỉ 0/11/1.5; điểm -0.1/10.1/NaN; grade tham chiếu NOSV/NOSUBJECT; kỳ 2026-3. Ca quyền dùng client unauthenticated và user outsider không có manager profile. Emulator dọn dữ liệu trước mỗi test.

## Rà soát test nền và PR

- Repo hiện ở `main` tại `86f0b3c`, bằng `origin/main`; working tree sạch. Nền G1 đã ghép qua merge commit `1178ede` (nhánh `g1-foundation`, commit `7d7fedf`); bằng chứng APK bổ sung ở `b098fd5`.
- Code nền có validation model, repository typed, kiểm tra reference khi tạo Student/Grade, ID grade xác định, rules manager-only; rules tests chặn guest, tự nâng quyền và document sai. Xóa sinh viên được mở có kiểm soát bằng bộ đếm `gradeCount` (xem docs/02); rules emulator có test xóa khi chưa/đã có điểm và tạo điểm sai bộ đếm.
- Báo cáo nghiệm thu trước đó ghi analyze PASS, 17 Flutter tests PASS và 6 Firestore emulator tests PASS. Lần chạy lại hiện không qua dependency resolution: máy có Dart 3.13.1 trong khi `pubspec.yaml` yêu cầu ^3.13.2; `flutter analyze` và `flutter test` đều dừng. Chạy lại với Flutter 3.47.2/Dart 3.13.2 theo CI trước khi ghi nhận xác minh mới.
- Không truy cập được trạng thái review/checks GitHub PR từ repo cục bộ. Merge trên main xác nhận code tích hợp nhưng không chứng minh Hiệp đã review; nhóm trưởng cần đối chiếu PR và reviewer/checks thật.
- Test hiện có kiểm tra nền model/repository/rules/bootstrap, không bao phủ UI và phần lớn luồng nghiệp vụ. Mỗi chủ story cần thêm ca đúng/sai và UI test khi làm module; loading/rỗng/lỗi không thể xem là đạt chỉ từ test mapping.

## Cập nhật 31/10/2026 (US09–US16)

Phần Khôi + Hiệp đã bổ sung test giao diện và kiểm tra học kỳ sau khi ma trận này được lập: `test/classes_stories_test.dart`
(US09–US12), `test/subjects_grades_stories_test.dart` (US13–US16), ca học kỳ trong `test/models_test.dart` và
`tools/firestore-tests/rules.test.mjs`. Bảng đối chiếu story với test và kết quả (130 test Flutter qua, 12 test emulator qua)
nằm ở mục 6 và 7 của [tài liệu module Lớp học, Môn học và Điểm](11-module-lop-mon-hoc-diem.md).

## Cập nhật 30/10/2026 (US01–US08)

Phần Bắc + Phát đã bổ sung test và ảnh minh chứng sau khi ma trận này được lập. Bảng đối chiếu story với từng file test thực tế nằm ở mục 7 của [tài liệu module Tài khoản và Sinh viên](10-module-sinh-vien-va-tai-khoan.md); các cột "còn thiếu" ở trên cho US01–US08 là trạng thái ngày 27/10.
