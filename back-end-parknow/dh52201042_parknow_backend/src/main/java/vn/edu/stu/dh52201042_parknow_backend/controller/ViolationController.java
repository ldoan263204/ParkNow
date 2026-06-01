package vn.edu.stu.dh52201042_parknow_backend.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import vn.edu.stu.dh52201042_parknow_backend.model.Violation;
import vn.edu.stu.dh52201042_parknow_backend.service.ViolationService;
import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/violations")
@CrossOrigin(origins = "*")
public class ViolationController {

    @Autowired
    private ViolationService violationService;

    @GetMapping
    public List<Violation> getAllViolations() {
        return violationService.getAllViolations();
    }

    @GetMapping("/{id}")
    public ResponseEntity<Violation> getViolationById(@PathVariable Long id) {
        return violationService.getViolationById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/lot/{lotId}")
    public List<Violation> getViolationsByLot(@PathVariable Long lotId) {
        return violationService.getViolationsByParkingLotId(lotId);
    }

    @GetMapping("/status/{status}")
    public List<Violation> getViolationsByStatus(@PathVariable String status) {
        return violationService.getViolationsByStatus(status);
    }

    @GetMapping("/staff/{staffId}")
    public List<Violation> getViolationsByStaff(@PathVariable Long staffId) {
        return violationService.getViolationsByStaff(staffId);
    }

    @GetMapping("/customer/{customerId}")
    public List<Violation> getViolationsByCustomer(@PathVariable Long customerId) {
        return violationService.getViolationsByCustomer(customerId);
    }

    // Tạo báo cáo vi phạm mới
    @PostMapping
    public Violation createViolation(@RequestBody Violation violation) {
        return violationService.createViolation(violation);
    }

    // Đánh dấu vi phạm đã xử lý
    @PutMapping("/{id}/resolve")
    public ResponseEntity<?> resolveViolation(@PathVariable Long id) {
        try {
            Violation resolved = violationService.resolveViolation(id);
            return ResponseEntity.ok(resolved);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteViolation(@PathVariable Long id) {
        violationService.deleteViolation(id);
        return ResponseEntity.noContent().build();
    }

    // --------------------------------------------------------
    // UPLOAD ẢNH BẰNG CHỨNG VI PHẠM (multipart/form-data)
    // --------------------------------------------------------
    @PostMapping("/upload")
    public ResponseEntity<?> uploadViolationImage(@RequestParam("file") MultipartFile file) {
        try {
            String uploadDir = "uploads/violations/";
            new File(uploadDir).mkdirs();
            String fileName = System.currentTimeMillis() + "_" + file.getOriginalFilename();
            Path filePath = Paths.get(uploadDir + fileName);
            Files.copy(file.getInputStream(), filePath, StandardCopyOption.REPLACE_EXISTING);
            String url = "http://10.0.2.2:8080/uploads/violations/" + fileName;
            return ResponseEntity.ok(Map.of("url", url));
        } catch (IOException e) {
            return ResponseEntity.status(500).body(Map.of("error", "Upload thất bại: " + e.getMessage()));
        }
    }
}

