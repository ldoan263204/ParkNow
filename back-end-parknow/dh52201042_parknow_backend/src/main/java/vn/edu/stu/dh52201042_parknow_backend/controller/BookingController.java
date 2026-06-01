package vn.edu.stu.dh52201042_parknow_backend.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import vn.edu.stu.dh52201042_parknow_backend.model.Booking;
import vn.edu.stu.dh52201042_parknow_backend.service.BookingService;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/bookings")
@CrossOrigin(origins = "*")
public class BookingController {

    @Autowired
    private BookingService bookingService;

    @GetMapping
    public List<Booking> getAllBookings() {
        return bookingService.getAllBookings();
    }

    @GetMapping("/{id}")
    public ResponseEntity<Booking> getBookingById(@PathVariable Long id) {
        return bookingService.getBookingById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/user/{userId}")
    public List<Booking> getBookingsByUser(@PathVariable Long userId) {
        return bookingService.getBookingsByUserId(userId);
    }

    @GetMapping("/lot/{lotId}")
    public List<Booking> getBookingsByLot(@PathVariable Long lotId) {
        return bookingService.getBookingsByParkingLotId(lotId);
    }

    @GetMapping("/lot/{lotId}/active")
    public List<String> getActiveSlots(@PathVariable Long lotId) {
        return bookingService.getActiveSlotsByParkingLotId(lotId);
    }

    @GetMapping("/status/{status}")
    public List<Booking> getBookingsByStatus(@PathVariable String status) {
        return bookingService.getBookingsByStatus(status);
    }

    // Tạo đặt chỗ mới (Chi phí được tính tự động)
    @PostMapping
    public ResponseEntity<?> createBooking(@RequestBody Booking booking) {
        try {
            Booking created = bookingService.createBooking(booking);
            return ResponseEntity.ok(created);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // Hủy đặt chỗ
    @PutMapping("/{id}/cancel")
    public ResponseEntity<?> cancelBooking(@PathVariable Long id) {
        try {
            Booking cancelled = bookingService.cancelBooking(id);
            return ResponseEntity.ok(cancelled);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // Check-in đặt chỗ (khi xe vào bãi)
    @PutMapping("/{id}/check-in")
    public ResponseEntity<?> checkInBooking(@PathVariable Long id) {
        try {
            Booking checkedIn = bookingService.checkInBooking(id);
            return ResponseEntity.ok(checkedIn);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // Hoàn thành đặt chỗ (khi xe ra khỏi bãi)
    @PutMapping("/{id}/complete")
    public ResponseEntity<?> completeBooking(@PathVariable Long id) {
        try {
            Booking completed = bookingService.completeBooking(id);
            return ResponseEntity.ok(completed);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }
}
