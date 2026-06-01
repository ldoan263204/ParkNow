package vn.edu.stu.dh52201042_parknow_backend.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import vn.edu.stu.dh52201042_parknow_backend.model.Shift;
import vn.edu.stu.dh52201042_parknow_backend.service.ShiftService;
import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/shifts")
@CrossOrigin(origins = "*")
public class ShiftController {

    @Autowired
    private ShiftService shiftService;

    @GetMapping
    public List<Shift> getAllShifts() {
        return shiftService.getAllShifts();
    }

    @GetMapping("/{id}")
    public ResponseEntity<Shift> getShiftById(@PathVariable Long id) {
        return shiftService.getShiftById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/staff/{staffId}")
    public List<Shift> getShiftsByStaff(@PathVariable Long staffId) {
        return shiftService.getShiftsByStaffId(staffId);
    }

    // Lấy ca trực đang hoạt động
    @GetMapping("/staff/{staffId}/active")
    public ResponseEntity<Shift> getActiveShift(@PathVariable Long staffId) {
        return shiftService.getActiveShift(staffId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    // Bắt đầu ca trực mới
    @PostMapping("/start")
    public ResponseEntity<?> startShift(@RequestBody Map<String, Long> body) {
        try {
            Long staffId = body.get("staffId");
            Long parkingLotId = body.get("parkingLotId");
            Shift shift = shiftService.startShift(staffId, parkingLotId);
            return ResponseEntity.ok(shift);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // Kết thúc ca trực
    @PutMapping("/{id}/end")
    public ResponseEntity<?> endShift(@PathVariable Long id) {
        try {
            Shift shift = shiftService.endShift(id);
            return ResponseEntity.ok(shift);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // Ghi nhận xe vào
    @PutMapping("/{id}/entry")
    public ResponseEntity<?> recordEntry(@PathVariable Long id, @RequestBody Map<String, String> body) {
        try {
            BigDecimal amount = new BigDecimal(body.getOrDefault("amount", "0"));
            String paymentType = body.getOrDefault("paymentType", "cash");
            Shift shift = shiftService.recordEntry(id, amount, paymentType);
            return ResponseEntity.ok(shift);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // Ghi nhận xe ra
    @PutMapping("/{id}/exit")
    public ResponseEntity<?> recordExit(@PathVariable Long id) {
        try {
            Shift shift = shiftService.recordExit(id);
            return ResponseEntity.ok(shift);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }
}
