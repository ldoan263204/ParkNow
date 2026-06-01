package vn.edu.stu.dh52201042_parknow_backend.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import vn.edu.stu.dh52201042_parknow_backend.model.Shift;
import vn.edu.stu.dh52201042_parknow_backend.repository.ShiftRepository;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
public class ShiftService {

    @Autowired
    private ShiftRepository shiftRepository;

    public List<Shift> getAllShifts() {
        return shiftRepository.findAll();
    }

    public Optional<Shift> getShiftById(Long id) {
        return shiftRepository.findById(id);
    }

    public List<Shift> getShiftsByStaffId(Long staffId) {
        return shiftRepository.findByStaffIdOrderByStartTimeDesc(staffId);
    }

    // Lấy ca trực đang hoạt động của nhân viên
    public Optional<Shift> getActiveShift(Long staffId) {
        return shiftRepository.findByStaffIdAndStatus(staffId, "active");
    }

    // Bắt đầu ca trực mới
    public Shift startShift(Long staffId, Long parkingLotId) {
        // Kiểm tra xem nhân viên có đang có ca trực nào đang hoạt động không
        Optional<Shift> activeShift = shiftRepository.findByStaffIdAndStatus(staffId, "active");
        if (activeShift.isPresent()) {
            throw new RuntimeException("Nhân viên đang có ca trực đang hoạt động!");
        }
        Shift shift = new Shift();
        shift.setStaffId(staffId);
        shift.setParkingLotId(parkingLotId);
        shift.setStartTime(LocalDateTime.now());
        shift.setStatus("active");
        shift.setTotalIn(0);
        shift.setTotalOut(0);
        shift.setCashRevenue(BigDecimal.ZERO);
        shift.setOnlineRevenue(BigDecimal.ZERO);
        return shiftRepository.save(shift);
    }

    // Kết thúc ca trực
    public Shift endShift(Long shiftId) {
        return shiftRepository.findById(shiftId).map(shift -> {
            shift.setEndTime(LocalDateTime.now());
            shift.setStatus("completed");
            return shiftRepository.save(shift);
        }).orElseThrow(() -> new RuntimeException("Không tìm thấy ca trực với ID: " + shiftId));
    }

    // Ghi nhận xe vào (tăng totalIn + doanh thu)
    public Shift recordEntry(Long shiftId, BigDecimal amount, String paymentType) {
        return shiftRepository.findById(shiftId).map(shift -> {
            int currentIn = shift.getTotalIn() != null ? shift.getTotalIn() : 0;
            shift.setTotalIn(currentIn + 1);
            
            BigDecimal cash = shift.getCashRevenue() != null ? shift.getCashRevenue() : BigDecimal.ZERO;
            BigDecimal online = shift.getOnlineRevenue() != null ? shift.getOnlineRevenue() : BigDecimal.ZERO;
            
            BigDecimal addAmount = amount != null ? amount : BigDecimal.ZERO;
            
            if ("cash".equals(paymentType)) {
                shift.setCashRevenue(cash.add(addAmount));
            } else {
                shift.setOnlineRevenue(online.add(addAmount));
            }
            return shiftRepository.save(shift);
        }).orElseThrow(() -> new RuntimeException("Không tìm thấy ca trực!"));
    }

    // Ghi nhận xe ra (tăng totalOut)
    public Shift recordExit(Long shiftId) {
        return shiftRepository.findById(shiftId).map(shift -> {
            int currentOut = shift.getTotalOut() != null ? shift.getTotalOut() : 0;
            shift.setTotalOut(currentOut + 1);
            return shiftRepository.save(shift);
        }).orElseThrow(() -> new RuntimeException("Không tìm thấy ca trực!"));
    }
}
