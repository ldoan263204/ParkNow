package vn.edu.stu.dh52201042_parknow_backend.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import vn.edu.stu.dh52201042_parknow_backend.model.ParkingLot;
import vn.edu.stu.dh52201042_parknow_backend.service.ParkingLotService;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/parking-lots")
@CrossOrigin(origins = "*") // Giúp App Flutter gọi API không bị lỗi bảo mật
public class ParkingLotController {

    @Autowired
    private ParkingLotService parkingLotService;

    // Lấy tất cả bãi đỗ xe đã được phê duyệt (dành cho Customer)
    @GetMapping
    public List<ParkingLot> getApprovedParkingLots() {
        return parkingLotService.getApprovedParkingLots();
    }

    // Lấy tất cả bãi đỗ xe (dành cho Admin)
    @GetMapping("/all")
    public List<ParkingLot> getAllParkingLots() {
        return parkingLotService.getAllParkingLots();
    }

    // Lọc bãi đỗ xe theo trạng thái
    @GetMapping("/status/{status}")
    public List<ParkingLot> getParkingLotsByStatus(@PathVariable String status) {
        return parkingLotService.getParkingLotsByStatus(status);
    }

    @GetMapping("/{id}")
    public ResponseEntity<ParkingLot> getParkingLotById(@PathVariable Long id) {
        return parkingLotService.getParkingLotById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public ParkingLot createParkingLot(@RequestBody ParkingLot parkingLot) {
        return parkingLotService.createParkingLot(parkingLot);
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> updateParkingLot(@PathVariable Long id, @RequestBody ParkingLot parkingLot) {
        try {
            ParkingLot updated = parkingLotService.updateParkingLot(id, parkingLot);
            return ResponseEntity.ok(updated);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // Admin phê duyệt bãi đỗ xe
    @PutMapping("/{id}/approve")
    public ResponseEntity<?> approveParkingLot(@PathVariable Long id) {
        try {
            ParkingLot approved = parkingLotService.approveParkingLot(id);
            return ResponseEntity.ok(approved);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // Admin từ chối bãi đỗ xe
    @PutMapping("/{id}/reject")
    public ResponseEntity<?> rejectParkingLot(@PathVariable Long id, @RequestBody Map<String, String> body) {
        try {
            String reason = body.get("reason");
            ParkingLot rejected = parkingLotService.rejectParkingLot(id, reason);
            return ResponseEntity.ok(rejected);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteParkingLot(@PathVariable Long id) {
        parkingLotService.deleteParkingLot(id);
        return ResponseEntity.noContent().build();
    }
}