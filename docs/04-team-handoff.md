# Bàn giao nền GĐ1 cho nhóm

## Thành viên và phạm vi

| Thành viên | Nhánh GĐ1 đề xuất | Việc đang nhận |
|---|---|---|
| Nguyễn Văn Bắc — nhóm trưởng | g1-foundation | G1-01: nền code/contract/PR. G1-02: Firebase + Android dùng chung. |
| Nguyễn Bá Phát | g1-model-review | G1-03: rà model, quan hệ, mô tả phương thức và 1 Class Diagram. |
| Nguyễn Minh Khôi | g1-wireframes | G1-04: wireframe toàn bộ màn hình, ít nhất 5 flow, style và điều hướng. |
| Nguyễn Huy Hiệp | g1-test-plan | G1-05: ma trận 16 stories, dữ liệu mẫu, rà test nền và PR nhóm trưởng. |

Đây là phân công GĐ1. Ba thành viên có thể nhận bản nền để làm việc GĐ1 ngay khi
PR nền được merge; chưa tự chuyển sang code GĐ2 trước khi cả 5 việc GĐ1 đạt.

## Mỗi người bắt đầu như sau

```powershell
git clone https://github.com/QLSV-Bac-Khoi-Hiep-Phat-N05-1-2026/appQuanLySInhVien.git
Set-Location appQuanLySInhVien
git switch main
git pull --ff-only origin main
git switch -c g1-model-review  # thay bằng nhánh của mình ở bảng trên
flutter pub get
flutter analyze
flutter test
```

Nếu đã có repo và còn thay đổi chưa commit, không reset/clean để cập nhật. Commit
vào nhánh riêng hoặc sao lưu trước. Mỗi thành viên dùng tài khoản GitHub và email
commit của mình; không dùng thông tin tác giả của nhóm trưởng.

Máy dùng Flutter 3.47.2 / Dart 3.13.2 hoặc phiên bản đáp ứng pubspec. Để chạy app
Android cần Android SDK + điện thoại/emulator. Để chỉ viết tài liệu và chạy unit
test, chưa cần Firestore cloud; không đánh đồng kết quả đó với chạy app Android.

## Một Firebase project dùng chung

- Firebase là dịch vụ cloud, không phải phần mềm cả nhóm phải tải về.
- Chỉ dùng project `quan-ly-sinh-vien-ba83b`; không tạo bốn project khác nhau.
- File firebase_options.dart/google-services.json là cấu hình kết nối, không phải
  tài khoản có quyền quản trị. Quyền dữ liệu vẫn do Authentication và rules kiểm soát.
- Nhóm trưởng cấu hình/deploy. Các bạn chạy `flutter pub get` để lấy thư viện SDK.
- Firebase CLI chỉ cần khi deploy/chạy emulator; không bắt buộc cho mỗi lần code UI.
- Tài khoản manager là tài khoản đăng nhập thử trong app, khác tài khoản quản trị
  Firebase Console. Không gửi mật khẩu/token vào PR, báo cáo hoặc commit.
- Database Singapore, Email/Password và 4 tài khoản thử đã được cấu hình; xem bằng chứng cloud ở docs/05-g1-cloud-evidence.json.

## Contract cho các module

| Module | Thành viên sở hữu | API/model dùng chung |
|---|---|---|
| Tài khoản | Bắc | AppUser, AuthService, FirebaseBootstrap |
| Sinh viên | Phát | Student; StudentDataService.students / createStudent |
| Lớp | Khôi | ClassRoom; StudentDataService.classes / watchStudentsInClass |
| Môn và điểm | Hiệp | Subject, Grade; subjects / saveGrade / watchGradesForStudent |

Firestore collections: users, students, classes, subjects, grades. ID nghiệp vụ
không đổi sau khi tạo; Grade có ID `studentId~subjectId~semester`. Không đổi tên
collection/trường hoặc kiểu dữ liệu riêng ở từng nhánh. Đề xuất thay đổi contract
trong PR nền trước khi các module phụ thuộc được merge.

Tất cả module nhận một instance StudentDataService dùng chung hoặc inject instance
trong test. Giao diện phải xử lý tải/rỗng/lỗi và hủy subscription khi rời màn hình.
Không gọi Admin SDK hoặc dùng service-account từ ứng dụng Flutter.

### Contract xóa sinh viên (US08, GĐ3)

- Có hộp xác nhận; hủy không thay đổi dữ liệu.
- Có điểm thì chặn xóa; chưa có điểm mới xóa.
- Đã triển khai bằng bộ đếm `gradeCount` + transaction + rules (xem docs/02); rules chỉ cho delete khi bộ đếm bằng 0.
- Không chỉ query grades trên client rồi xóa: có nguy cơ nhập điểm đồng thời.
- Phát và Hiệp phối hợp bổ sung metadata đếm điểm, cập nhật nguyên tử cùng tạo
  điểm, và kiểm tra bằng rules/transaction; hoặc dùng một backend duy nhất có
  transaction tương đương. Bắc duyệt thay đổi contract/rules trước khi merge.
- Phải có test: xóa khi chưa có điểm, có điểm, hủy, tài khoản không quyền và xung
  đột tạo điểm/xóa. Không mở `allow delete: if manager()` đơn lẻ để vượt test.
- Phần nền GĐ1 chưa tuyên bố US08 hoàn tất. Đây là hợp đồng cho GĐ3.

## Kiểm thử và mở PR

```powershell
flutter analyze
flutter test
npm --prefix tools/firestore-tests ci
& ./tools/firestore-tests/node_modules/.bin/firebase.cmd emulators:exec --config firebase.test.json --only firestore --project demo-qlsv "npm --prefix tools/firestore-tests test"
```

Emulator chỉ dùng project giả `demo-qlsv`, không ghi dữ liệu vào cloud. Cần Java 21
và Node 24 cho công cụ test hiện tại. Unit tests dùng FakeFirestore không chứng
minh database cloud đã hoạt động; rules tests mới kiểm tra quyền phía server.

PR ghi mã việc (G1-03/G1-04/G1-05), sản phẩm bàn giao, kết quả test và link/ảnh.
Nhóm trưởng review PR thành viên; Hiệp rà PR nền của nhóm trưởng trong việc G1-05.
Không tự ghi đã được Hiệp duyệt nếu chưa có review thật.

Merge từng PR, giữ lịch sử commit của người làm, chạy lại kiểm tra trên main.
Excel chỉ đánh Đạt khi có PR thật, đã merge và có nghiệm thu. Việc chưa đủ điều
kiện phải ghi Chưa đạt cùng lý do. GĐ2 chỉ mở khi cả GĐ1 và kiểm tra chung đạt.
