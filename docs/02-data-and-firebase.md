# Thiết kế dữ liệu và kết nối Firebase

## Project và phạm vi nền

Dùng project Firebase riêng của nhóm `qlsv-n05-phat-khoi`, cấu hình Android và web trong
`lib/firebase_options.dart` (Android còn có `android/app/google-services.json`).
Không lưu mật khẩu, refresh token, service-account JSON trong Firestore/Git.
Firebase Auth quản lý thông tin xác thực. Các manager dùng chung dữ liệu nghiệp vụ.

## Đối tượng và Documents

| Đối tượng | Document path | Thuộc tính lưu trong document | Phương thức nền |
|---|---|---|---|
| AppUser | users/{uid của Firebase Auth} | email: String; displayName: String; role: 'manager' | fromMap, toMap; AuthService.signIn/signOut/updateDisplayName |
| Student | students/{studentId} | name: String; major: String; age: int; email: String (có thể rỗng); classId: String hoặc null | fromMap, toMap, validate; createStudent |
| ClassRoom | classes/{classId} | name: String; major: String; cohort: String | fromMap, toMap; create/update/getById/watchAll |
| Subject | subjects/{subjectId} | name: String; credits: int | fromMap, toMap; create/update/getById/watchAll |
| Grade | grades/{studentId~subjectId~semester} | studentId: String; subjectId: String; semester: String; score: double | fromMap, toMap; saveGrade; watchGradesForStudent |

ID không lưu lặp trong dữ liệu document; snapshot.id là nguồn ID chính thức.
Student là model độc lập, thuộc tính có kiểu cụ thể và không đổi trực tiếp sau khi khởi tạo.
Cập nhật hồ sơ bằng đối tượng mới; cấu trúc document và ID Firestore được giữ nguyên.

## Quan hệ và ràng buộc

1. Firebase Auth User ↔ AppUser: 1–1 qua uid. Tài khoản đã xác thực nhưng thiếu hồ sơ
   manager không được đọc dữ liệu nghiệp vụ.
2. ClassRoom → Student: 1–n qua classId. Student có thể chưa xếp lớp (null).
3. Student → Grade: 1–n qua studentId.
4. Subject → Grade: 1–n qua subjectId.
5. Student ↔ Subject: n–n qua Grade, phân biệt bằng semester.

Mã nghiệp vụ 1–80 ký tự A–Z/a–z/0–9/_/-. Không đổi mã khi cập nhật.
Grade có khóa xác định, vì vậy lưu lại cùng bộ (sinh viên, môn, kỳ) không sinh
bản ghi trùng. Điểm 0–10; tín chỉ nguyên 1–10; tuổi nguyên 1–120.

## API dùng chung

```dart
final data = StudentDataService(FirebaseFirestore.instance);
await data.classes.create(ClassRoom(
  id: 'CNTT01', name: 'Công nghệ thông tin 01', major: 'CNTT', cohort: 'K17',
));
await data.createStudent(Student(
  studentId: 'SV001', name: 'Sinh viên mẫu', major: 'CNTT', age: 21,
  classId: 'CNTT01',
));
await data.subjects.create(Subject(id: 'MOB01', name: 'Lập trình di động', credits: 3));
await data.saveGrade(Grade(
  studentId: 'SV001', subjectId: 'MOB01', semester: '2026-1', score: 8.5,
));
final students = data.watchStudentsInClass('CNTT01');
final grades = data.watchGradesForStudent('SV001');
```

Chỉ gọi các lệnh này sau khi Firebase khởi tạo và manager đăng nhập. Ví dụ là
API cho thành viên tích hợp, không được chạy seed tự động lúc mở ứng dụng.

- `withConverter<T>` ánh xạ snapshot ↔ đối tượng; `fromMap/toMap` nằm ở model.
- `create` dùng transaction để chặn ghi đè mã tồn tại; `update` không tạo bản ghi mới.
- `createStudent` kiểm tra lớp; `saveGrade` kiểm tra sinh viên và môn trong transaction.
- Rules kiểm tra lại dữ liệu và references ngay cả khi client bỏ qua service.
- Không dùng `users.watchAll/create`: rules chỉ cho đọc hồ sơ chính mình và sửa displayName.
- Xóa sinh viên (US08): document `students/{id}` có thêm trường `gradeCount` (không nằm trong
  model `Student`). `createStudent` ghi 0; `saveGrade` tăng đúng 1 trong cùng transaction khi
  tạo điểm mới; `updateStudent` không gửi trường này. Rules chỉ cho tạo với `gradeCount == 0`,
  chỉ cho tăng đúng 1 cùng lúc tạo điểm, chặn giảm, và chỉ cho `delete` khi `gradeCount == 0`.
  Hồ sơ cũ chưa có `gradeCount` (tạo trước thay đổi này) cần được bổ sung trường này
  bằng Console/Admin SDK trước khi sửa, nhập điểm hoặc xóa.
- Chưa có phân trang; phù hợp quy mô bài tập. Nếu dữ liệu tăng, thêm phân trang
  thay vì tải tất cả. Hủy stream subscriptions khi rời màn hình/đăng xuất.

## Khởi tạo và quyền truy cập

`main()` bọc MyApp bằng FirebaseAppLoader. Khởi tạo lỗi có nút thử lại;
MyApp riêng vẫn dùng được trong widget test, không cần gọi dịch vụ thật.
Khởi tạo SDK thành công chưa đồng nghĩa Firestore có database hoặc đọc/ghi được.

`firestore.rules` yêu cầu đăng nhập và hồ sơ `users/{uid}.role == 'manager'`.
Client không thể tạo hồ sơ quản lý hay tự nâng quyền. Chủ project cấp 4 tài khoản
bằng Firebase Console/Admin SDK, bật Email/Password và tạo profile tương ứng.
Chỉ displayName của chính mình được cập nhật; email và role bất biến từ client.
Không mở rules `allow read, write: if true` để chạy thử.

## Thiết lập cloud

1. Xác minh project trước khi thao tác: `firebase projects:list`.
2. Tạo Firestore Native/Standard database `(default)` và chọn khu vực phù hợp.
   Việc chọn khu vực là cấu hình lâu dài; nhóm dùng `asia-southeast1` (Singapore)
   nếu tạo mới. Không nâng cấp gói thanh toán cho phần bài tập này.
3. Bật Authentication → Email/Password. Chủ project tạo tài khoản và profile manager.
4. Triển khai rules/indexes của project này bằng lệnh bên dưới.
5. Chạy Android bằng `flutter run` sau khi đăng nhập ở module US01, kiểm tra
   tạo lớp → sinh viên → môn → điểm → đọc lại trên Console.

```powershell
flutter pub get
npx --yes --package firebase-tools firebase deploy --only firestore:rules,firestore:indexes --project qlsv-n05-phat-khoi
```

Chỉ Android đã có cấu hình Firebase. Web/Windows/iOS cần đăng ký ứng dụng riêng
bằng FlutterFire CLI trước khi chạy; không dùng Android appId thay cho Web appId.

## Kiểm thử local không tác động dữ liệu thật

```powershell
flutter analyze
flutter test
Set-Location tools/firestore-tests
npm ci
Set-Location ../..
& ./tools/firestore-tests/node_modules/.bin/firebase.cmd emulators:exec --only firestore --project demo-qlsv "npm --prefix tools/firestore-tests test"
```

Emulator cần Java được Firebase CLI hiện tại hỗ trợ. `demo-qlsv` là project giả,
test tự tạo và dọn dữ liệu riêng trong emulator; không cấp manager trên cloud.
Test rules xác nhận chặn khách, chặn tự cấp quyền, chặn dữ liệu sai/reference sai,
cho phép manager đọc/ghi đúng và chỉ sửa tên của chính mình.

Để app Android Emulator nối vào máy local:

```powershell
flutter run --dart-define=USE_FIREBASE_EMULATORS=true --dart-define=FIREBASE_EMULATOR_HOST=10.0.2.2
```

Máy thật dùng IP LAN của máy chạy emulator. Mặc định app dùng cloud; không bật
emulator trong release. Kiểm thử Dart với FakeFirestore chỉ xác minh logic/mapping,
không thay thế kiểm thử rules bằng emulator hoặc nghiệm thu Android trên cloud.

## Tài liệu chính thức

- https://firebase.google.com/docs/flutter/setup
- https://firebase.google.com/docs/firestore/query-data/get-data#custom_objects
- https://firebase.google.com/docs/firestore/security/rules-conditions
