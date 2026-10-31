# EduSpace — Quản lý sinh viên

Ứng dụng Flutter/Dart cho người quản lý: hồ sơ sinh viên, lớp học, môn học và bảng điểm.

## Chức năng hiện có

- Trang chủ theo phong cách mẫu học tập, bố cục phù hợp điện thoại và máy tính.
- Sinh viên: tìm kiếm, lọc theo lớp, xem hồ sơ, thêm và sửa thông tin.
- Lớp học: thêm/sửa và xem danh sách sinh viên của lớp.
- Môn học: tìm kiếm, thêm môn; kiểm tra mã trùng và tín chỉ nguyên 1–10.
- Bảng điểm: chọn sinh viên; nhập/cập nhật điểm theo môn và học kỳ; lưu cùng bộ khóa cập nhật một bản ghi.
- Hồ sơ quản lý: xem thông tin, sửa tên và đăng xuất.
- Màn hình mẫu học tập Câu 5 được giữ riêng theo yêu cầu bài tập lớn.

## Chạy dự án

```sh
flutter pub get
flutter run -d chrome --web-port 51238
```

Trên web có hai cách dùng: **Đăng nhập Firebase** (dữ liệu thật trên project `qlsv-n05-phat-khoi`, cần tài khoản quản lý) hoặc **Khám phá bản trình diễn** (dữ liệu mẫu lưu trên trình duyệt, không ghi Firebase; giữ cùng địa chỉ/cổng để dùng lại dữ liệu đã lưu). Muốn chạy web với Firebase, cần đăng ký ứng dụng web: `flutterfire configure --project=qlsv-n05-phat-khoi --platforms=android,web`.

Android đã có cấu hình Firebase. Chọn thiết bị bằng `flutter devices`, sau đó `flutter run -d <device-id>` để sử dụng đăng nhập Firebase hoặc chế độ trình diễn. Giao diện cloud phải được nghiệm thu trên Android trước khi đánh dấu toàn bộ user stories hoàn thành.

## Cấu trúc chính

- `lib/screens`: đăng nhập, không gian quản lý, môn học, bảng điểm, màn hình mẫu Câu 5.
- `lib/models`: AppUser, Student, ClassRoom, Subject và Grade; mapping Firestore.
- `lib/services`: trạng thái dữ liệu demo/cloud, xác thực và repository có kiểu.
- `lib/ui`: giao diện dùng chung và form nhập dữ liệu.
- `lib/widgets/firebase_app_loader.dart`: khởi tạo Firebase và thử lại khi lỗi.
- `test`: kiểm thử model, repository, store, màn hình và tích hợp.

Student là model độc lập với thuộc tính có kiểu và bất biến. Khi sửa hồ sơ, tạo đối tượng mới; JSON và document Firestore giữ cùng cấu trúc.

## Kiểm tra và phạm vi

```sh
flutter analyze
flutter test
flutter build web --release
```

Xóa sinh viên có xác nhận và chặn nếu đã có điểm, cả ở demo lẫn Firebase. Trên Firebase, mỗi hồ sơ sinh viên có bộ đếm `gradeCount` tăng cùng giao dịch tạo điểm; rules chỉ cho xóa khi bộ đếm bằng 0 nên điểm không bị mồ côi khi nhập điểm và xóa xảy ra đồng thời. Web chưa cấu hình đăng nhập Firebase; không dùng kết quả demo để thay cho nghiệm thu cloud.

## Tài liệu

- [16 user stories và tiêu chí nghiệm thu](docs/01-user-stories.md).
- [Model, Firestore và hướng dẫn thiết lập](docs/02-data-and-firebase.md).
- [Lịch sử kiểm chứng](docs/03-verification.md).
- [Ma trận kiểm thử](docs/07-test-matrix.md).
- [Class Diagram và sơ đồ thuật toán](docs/09-class-diagram-va-so-do.md).
- [Tài liệu code module Tài khoản và Sinh viên](docs/10-module-sinh-vien-va-tai-khoan.md).
- [Bằng chứng kiểm tra Firebase cloud nền của project cũ trước khi tách nhóm](docs/05-g1-cloud-evidence.json); ảnh nghiệm thu với project mới nằm ở [docs/screenshots/firebase-that](docs/screenshots/firebase-that/README.md).

Các bài thực hành Generics/Pavlova và màn hình placeholder cũ đã được bỏ khỏi ứng dụng chính. Lịch sử thay đổi vẫn nằm trong Git.
