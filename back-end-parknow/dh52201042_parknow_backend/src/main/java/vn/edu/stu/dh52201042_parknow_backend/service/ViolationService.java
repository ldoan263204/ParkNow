package vn.edu.stu.dh52201042_parknow_backend.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import vn.edu.stu.dh52201042_parknow_backend.model.Violation;
import vn.edu.stu.dh52201042_parknow_backend.repository.ViolationRepository;
import java.util.List;
import java.util.Optional;

import vn.edu.stu.dh52201042_parknow_backend.repository.BookingRepository;
import vn.edu.stu.dh52201042_parknow_backend.model.Booking;
import java.util.stream.Collectors;
import java.util.ArrayList;

@Service
public class ViolationService {

    @Autowired
    private ViolationRepository violationRepository;

    @Autowired
    private BookingRepository bookingRepository;

    public List<Violation> getViolationsByCustomer(Long customerId) {
        List<Booking> bookings = bookingRepository.findByUserId(customerId);
        if (bookings.isEmpty()) {
            return new ArrayList<>();
        }
        List<String> plates = bookings.stream()
                .map(Booking::getVehiclePlate)
                .filter(plate -> plate != null && !plate.trim().isEmpty())
                .distinct()
                .collect(Collectors.toList());
        if (plates.isEmpty()) {
            return new ArrayList<>();
        }
        return violationRepository.findByVehiclePlateIn(plates);
    }

    public List<Violation> getAllViolations() {
        return violationRepository.findAll();
    }

    public Optional<Violation> getViolationById(Long id) {
        return violationRepository.findById(id);
    }

    public List<Violation> getViolationsByParkingLotId(Long parkingLotId) {
        return violationRepository.findByParkingLotId(parkingLotId);
    }

    public List<Violation> getViolationsByStatus(String status) {
        return violationRepository.findByStatus(status);
    }

    public List<Violation> getViolationsByStaff(Long staffId) {
        return violationRepository.findByReportedBy(staffId);
    }

    // Nhân viên tạo báo cáo vi phạm mới
    public Violation createViolation(Violation violation) {
        return violationRepository.save(violation);
    }

    // Cập nhật trạng thái vi phạm thành đã xử lý
    public Violation resolveViolation(Long id) {
        return violationRepository.findById(id).map(violation -> {
            violation.setStatus("resolved");
            violation.setResolvedAt(java.time.LocalDateTime.now());
            return violationRepository.save(violation);
        }).orElseThrow(() -> new RuntimeException("Không tìm thấy vi phạm với ID: " + id));
    }

    public void deleteViolation(Long id) {
        violationRepository.deleteById(id);
    }
}
