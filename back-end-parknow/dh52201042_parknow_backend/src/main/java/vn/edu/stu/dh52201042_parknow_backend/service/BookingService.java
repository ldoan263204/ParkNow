package vn.edu.stu.dh52201042_parknow_backend.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import vn.edu.stu.dh52201042_parknow_backend.model.Booking;
import vn.edu.stu.dh52201042_parknow_backend.model.ParkingLot;
import vn.edu.stu.dh52201042_parknow_backend.repository.BookingRepository;
import vn.edu.stu.dh52201042_parknow_backend.repository.ParkingLotRepository;
import java.math.BigDecimal;
import java.time.Duration;
import java.util.List;
import java.util.Optional;

@Service
public class BookingService {

    @Autowired
    private BookingRepository bookingRepository;

    @Autowired
    private ParkingLotRepository parkingLotRepository;

    public List<Booking> getAllBookings() {
        return bookingRepository.findAll();
    }

    public Optional<Booking> getBookingById(Long id) {
        return bookingRepository.findById(id);
    }

    public List<Booking> getBookingsByUserId(Long userId) {
        return bookingRepository.findByUserId(userId);
    }

    public List<Booking> getBookingsByParkingLotId(Long parkingLotId) {
        return bookingRepository.findByParkingLotId(parkingLotId);
    }

    public List<Booking> getBookingsByStatus(String status) {
        return bookingRepository.findByStatus(status);
    }

    /**
     * Tạo đặt chỗ mới — tính phí tự động và lưu phương thức thanh toán.
     * paymentMethod được truyền vào từ client (momo/card/cash).
     */
    public List<String> getActiveSlotsByParkingLotId(Long lotId) {
        List<Booking> activeBookings = bookingRepository.findByParkingLotIdAndStatusIn(
                lotId, List.of("confirmed", "checked_in")
        );
        return activeBookings.stream()
                .map(Booking::getSlotNumber)
                .filter(slot -> slot != null && !slot.isEmpty())
                .toList();
    }

    public Booking createBooking(Booking booking) {
        ParkingLot lot = parkingLotRepository.findById(booking.getParkingLotId())
                .orElseThrow(() -> new RuntimeException("Không tìm thấy bãi đỗ xe!"));

        // Validate trùng slot_number
        if (booking.getSlotNumber() != null && !booking.getSlotNumber().isEmpty()) {
            boolean isOccupied = bookingRepository.existsByParkingLotIdAndSlotNumberAndStatusIn(
                    booking.getParkingLotId(),
                    booking.getSlotNumber(),
                    List.of("confirmed", "checked_in")
            );
            if (isOccupied) {
                throw new RuntimeException("Vị trí đỗ " + booking.getSlotNumber() + " đã được chọn hoặc đang đỗ xe!");
            }
        }

        if (lot.getAvailableSlots() <= 0) {
            throw new RuntimeException("Bãi đỗ xe đã hết chỗ trống!");
        }

        // Tính phí gửi xe
        long hours = Duration.between(booking.getStartTime(), booking.getEndTime()).toHours();
        if (hours <= 0) hours = 1;
        BigDecimal parkingFee = lot.getPricePerHour().multiply(BigDecimal.valueOf(hours));
        BigDecimal serviceFee = parkingFee.multiply(new BigDecimal("0.05")); // Phí dịch vụ 5%
        BigDecimal tax = parkingFee.multiply(new BigDecimal("0.08"));        // Thuế 8%
        BigDecimal totalCost = parkingFee.add(serviceFee).add(tax);

        booking.setParkingFee(parkingFee);
        booking.setServiceFee(serviceFee);
        booking.setTax(tax);
        booking.setTotalCost(totalCost);
        booking.setStatus("confirmed");

        // Cập nhật trạng thái thanh toán dựa vào phương thức
        // Tiền mặt tại quầy → chưa trả; Ví điện tử / Thẻ → đã thanh toán online
        if ("cash".equals(booking.getPaymentMethod())) {
            booking.setPaymentStatus("unpaid");
        } else {
            booking.setPaymentStatus("paid");
        }

        // Giảm số chỗ trống
        lot.setAvailableSlots(lot.getAvailableSlots() - 1);
        parkingLotRepository.save(lot);

        return bookingRepository.save(booking);
    }

    // Hủy đặt chỗ
    public Booking cancelBooking(Long id) {
        return bookingRepository.findById(id).map(booking -> {
            if ("completed".equals(booking.getStatus()) || "checked_in".equals(booking.getStatus())) {
                throw new RuntimeException("Không thể hủy đặt chỗ đã check-in hoặc đã hoàn thành!");
            }
            booking.setStatus("cancelled");
            // Tăng lại số chỗ trống
            ParkingLot lot = parkingLotRepository.findById(booking.getParkingLotId()).orElse(null);
            if (lot != null) {
                lot.setAvailableSlots(lot.getAvailableSlots() + 1);
                parkingLotRepository.save(lot);
            }
            return bookingRepository.save(booking);
        }).orElseThrow(() -> new RuntimeException("Không tìm thấy đặt chỗ với ID: " + id));
    }

    /**
     * Check-in đặt chỗ (xe vào bãi).
     * CHỈ cho phép nếu booking đang ở trạng thái "confirmed".
     * Từ chối nếu đã cancelled, completed hoặc đã checked_in rồi.
     */
    public Booking checkInBooking(Long id) {
        return bookingRepository.findById(id).map(booking -> {
            String status = booking.getStatus();
            if ("checked_in".equals(status)) {
                throw new RuntimeException("Đặt chỗ này đã được check-in rồi!");
            }
            if ("cancelled".equals(status)) {
                throw new RuntimeException("Không thể check-in đặt chỗ đã bị hủy!");
            }
            if ("completed".equals(status)) {
                throw new RuntimeException("Đặt chỗ này đã hoàn thành, không thể check-in lại!");
            }
            booking.setStatus("checked_in");
            return bookingRepository.save(booking);
        }).orElseThrow(() -> new RuntimeException("Không tìm thấy đặt chỗ với ID: " + id));
    }

    /**
     * Hoàn thành đặt chỗ (xe ra khỏi bãi).
     * CHỈ hoàn thành nếu đang ở trạng thái "checked_in".
     */
    public Booking completeBooking(Long id) {
        return bookingRepository.findById(id).map(booking -> {
            if ("completed".equals(booking.getStatus())) {
                throw new RuntimeException("Đặt chỗ này đã hoàn thành trước đó!");
            }
            if (!"checked_in".equals(booking.getStatus())) {
                throw new RuntimeException("Chỉ có thể hoàn thành đặt chỗ đang ở trạng thái check-in!");
            }
            booking.setStatus("completed");
            // Tăng lại số chỗ trống khi xe ra
            ParkingLot lot = parkingLotRepository.findById(booking.getParkingLotId()).orElse(null);
            if (lot != null) {
                lot.setAvailableSlots(lot.getAvailableSlots() + 1);
                parkingLotRepository.save(lot);
            }
            return bookingRepository.save(booking);
        }).orElseThrow(() -> new RuntimeException("Không tìm thấy đặt chỗ với ID: " + id));
    }
}
