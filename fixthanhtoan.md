# 📋 PARKNOW - DANH SÁCH VIỆC CẦN LÀM (TO-DO & BUG FIXES)
**Ngày cập nhật:** 01/06/2026
**Trạng thái:** Giai đoạn Hoàn thiện (Final Phase)

Dưới đây là danh sách các lỗi cần khắc phục và các tính năng cần phát triển để hoàn thiện dự án ParkNow (Flutter + Spring Boot + MySQL).

---

## 🚨 PHẦN 1: CÁC LỖI NGHIỆP VỤ & KỸ THUẬT CẦN VÁ (CRITICAL BUGS)

1. **Lỗi Ánh xạ Database (Thanh toán):**
   - **Tình trạng:** Khi lưu Booking, MySQL báo lỗi `Field 'customer_id' doesn't have a default value`.
   - **Nguyên nhân:** Entity `Booking.java` đang dùng tên biến `userId` không khớp với cột `customer_id` trong MySQL.
   - **Hành động:** Đồng bộ tên cột giữa Spring Boot và MySQL.

2. **Thủng Bảo Mật JWT (Nhân Viên):**
   - **Tình trạng:** Lớp `StaffService.dart` gọi API trần, không đính kèm Token JWT vào header `Authorization`.
   - **Hành động:** Sử dụng `AuthenticatedClient` thay cho `http` thông thường trong toàn bộ `StaffService`.

3. **Lỗi Nghiệp vụ Check-in (Backend):**
   - **Tình trạng:** Backend cho phép nhân viên check-in những đơn đặt chỗ đã bị hủy (cancelled) hoặc đã hoàn thành (completed).
   - **Hành động:** Bổ sung logic kiểm tra trạng thái trước khi cập nhật sang `checked_in`.

4. **Memory Leak (Rò rỉ bộ nhớ):**
   - **Tình trạng:** `AuthenticatedClient.dart` liên tục tạo mới `http.Client()` mà không đóng lại (close).
   - **Hành động:** Sửa lại thành Singleton hoặc thêm cơ chế `close()` đúng chuẩn.

5. **Lỗi Giao diện Đồng hồ Ca trực:**
   - **Tình trạng:** Hàm tính thời gian ca trực đúng, nhưng giao diện không tự động cập nhật theo từng giây.
   - **Hành động:** Sử dụng `Timer.periodic` kết hợp `setState` để đồng hồ đếm giờ hiển thị trực tiếp.

---

## 🛠️ PHẦN 2: CÁC DỮ LIỆU ĐANG GẮN CỨNG (HARDCODED LOGIC) CẦN SỬA

1. **Phương thức Thanh toán Bị Bỏ Qua:**
   - **Tình trạng:** UI có chọn phương thức thanh toán nhưng dữ liệu không được lưu vào DB. Nhân viên không biết khách đã trả tiền chưa.
   - **Hành động:** Bổ sung trường `paymentMethod` (momo/card/cash) và `paymentStatus` (paid/unpaid) vào CSDL và logic xử lý ở cả 2 phía.

2. **Bãi Đỗ Xe Ảo (Nhân Viên):**
   - **Tình trạng:** Nhân viên khi nhận ca luôn bị ép vào bãi đỗ số 1 (`parkingLotId = 1`). Tên bãi đỗ trên app hiển thị cố định là "Bãi đỗ ParkNow".
   - **Hành động:** Tạo màn hình chọn bãi đỗ trước khi nhận ca. Load tên bãi đỗ thực tế từ API.

3. **Số liệu Thống kê Ảo (Nhân Viên & Admin):**
   - **Tình trạng:** Biểu đồ nửa vòng tròn của nhân viên luôn báo 45/100 chỗ. Thống kê "Doanh thu hôm nay" và biểu đồ 7 ngày của Admin là số gõ tay.
   - **Hành động:** Xây dựng các API Dashboard / Analytics ở Backend để trả về số liệu thật.

4. **Tên Bãi Đỗ Bị Thiếu (Khách hàng):**
   - **Tình trạng:** Vé của khách hàng chỉ hiển thị ID (VD: "Bãi xe số 1").
   - **Hành động:** Thực hiện truy vấn tên bãi đỗ dựa trên ID để hiển thị.

---

## 🚀 PHẦN 3: CÁC TÍNH NĂNG CHƯA ĐƯỢC PHÁT TRIỂN (MISSING FEATURES)

### A. Tích hợp Hardware & Bản đồ
1. **Quét Mã QR Chuyên Nghiệp:** Tích hợp `mobile_scanner` để thay thế cho việc gõ hardcode hiện tại.
2. **Quyền Truy cập & Định vị:** Tích hợp `permission_handler` để xin quyền GPS hợp lệ trên thiết bị thật.
3. **Chỉ Đường (Routing):** Sử dụng OSRM để vẽ chỉ đường từ GPS khách hàng đến bãi đỗ xe.
4. **Upload Ảnh Vi Phạm:** Cập nhật URL server thay vì IP `10.0.2.2`, xử lý luồng chụp ảnh (`image_picker`) và upload thành file (multipart).

### B. Nghiệp Vụ Cốt Lõi
1. **Tra Cứu Đặt Chỗ Thủ Công (Nhân Viên):** Xây dựng màn hình danh sách các đặt chỗ tại bãi, cho phép tìm bằng biển số / SĐT (khi khách hỏng QR Code).
2. **Quản Lý Bãi Đỗ Xe (Admin):** Bổ sung nút và Form "Thêm mới bãi đỗ" và code chức năng "Sửa" bãi đỗ.
3. **Mã Nhân Viên (Staff Code):** Tự sinh mã định danh (VD: STAFF_001) khi tạo tài khoản Staff. Sử dụng mã này (`qr_flutter`) để vẽ thành QR Code cá nhân trên hồ sơ.
4. **Quản Lý Người Dùng (Admin):** Xây dựng giao diện hiển thị danh sách, thêm, sửa, khóa (block) tài khoản người dùng.
5. **Hủy Đặt Chỗ (Khách Hàng):** Hiện UI cho phép khách hàng gọi API hủy đặt chỗ khi chưa quá giờ.