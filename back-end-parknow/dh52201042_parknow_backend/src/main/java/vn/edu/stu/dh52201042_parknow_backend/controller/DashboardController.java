package vn.edu.stu.dh52201042_parknow_backend.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import vn.edu.stu.dh52201042_parknow_backend.model.Booking;
import vn.edu.stu.dh52201042_parknow_backend.model.ParkingLot;
import vn.edu.stu.dh52201042_parknow_backend.model.Shift;
import vn.edu.stu.dh52201042_parknow_backend.model.Violation;
import vn.edu.stu.dh52201042_parknow_backend.repository.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

/**
 * API Tổng hợp số liệu Dashboard cho Admin.
 * Trả về KPIs thực tế từ Database thay vì dữ liệu hardcode.
 */
@RestController
@RequestMapping("/api/dashboard")
@CrossOrigin(origins = "*")
public class DashboardController {

    @Autowired
    private BookingRepository bookingRepository;

    @Autowired
    private ParkingLotRepository parkingLotRepository;

    @Autowired
    private ViolationRepository violationRepository;

    @Autowired
    private ShiftRepository shiftRepository;

    @Autowired
    private UserRepository userRepository;

    /**
     * GET /api/dashboard/stats
     * Trả về KPI tổng hợp: Doanh thu hôm nay, Đặt chỗ, Vi phạm chờ xử lý, Tổng users.
     */
    @GetMapping("/stats")
    public Map<String, Object> getStats() {
        Map<String, Object> stats = new LinkedHashMap<>();

        // Doanh thu hôm nay (tổng từ các ca trực completed + active hôm nay)
        LocalDateTime todayStart = LocalDate.now().atStartOfDay();
        LocalDateTime todayEnd = LocalDate.now().atTime(23, 59, 59);
        List<Shift> todayShifts = shiftRepository.findAll().stream()
                .filter(s -> s.getStartTime() != null
                        && s.getStartTime().isAfter(todayStart)
                        && s.getStartTime().isBefore(todayEnd))
                .collect(Collectors.toList());

        BigDecimal todayRevenue = todayShifts.stream()
                .map(s -> {
                    BigDecimal cash = s.getCashRevenue() != null ? s.getCashRevenue() : BigDecimal.ZERO;
                    BigDecimal online = s.getOnlineRevenue() != null ? s.getOnlineRevenue() : BigDecimal.ZERO;
                    return cash.add(online);
                })
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        // Đếm booking đang active (confirmed + checked_in)
        long activeBookings = bookingRepository.findAll().stream()
                .filter(b -> "confirmed".equals(b.getStatus()) || "checked_in".equals(b.getStatus()))
                .count();

        // Violations chờ xử lý
        long pendingViolations = violationRepository.findAll().stream()
                .filter(v -> "pending".equals(v.getStatus()))
                .count();

        // Tổng người dùng
        long totalUsers = userRepository.count();

        // Tổng bãi đỗ
        long totalLots = parkingLotRepository.count();

        stats.put("todayRevenue", todayRevenue);
        stats.put("activeBookings", activeBookings);
        stats.put("pendingViolations", pendingViolations);
        stats.put("totalUsers", totalUsers);
        stats.put("totalLots", totalLots);
        return stats;
    }

    /**
     * GET /api/dashboard/revenue-chart
     * Trả về doanh thu 7 ngày gần nhất (mảng 7 phần tử, index 0 = 6 ngày trước).
     */
    @GetMapping("/revenue-chart")
    public List<Map<String, Object>> getRevenueChart() {
        List<Map<String, Object>> chart = new ArrayList<>();
        for (int i = 6; i >= 0; i--) {
            LocalDate date = LocalDate.now().minusDays(i);
            LocalDateTime start = date.atStartOfDay();
            LocalDateTime end = date.atTime(23, 59, 59);

            BigDecimal dayRevenue = shiftRepository.findAll().stream()
                    .filter(s -> s.getStartTime() != null
                            && s.getStartTime().isAfter(start)
                            && s.getStartTime().isBefore(end))
                    .map(s -> {
                        BigDecimal cash   = s.getCashRevenue()   != null ? s.getCashRevenue()   : BigDecimal.ZERO;
                        BigDecimal online = s.getOnlineRevenue() != null ? s.getOnlineRevenue() : BigDecimal.ZERO;
                        return cash.add(online);
                    })
                    .reduce(BigDecimal.ZERO, BigDecimal::add);

            Map<String, Object> point = new LinkedHashMap<>();
            point.put("date", date.toString());
            point.put("revenue", dayRevenue);
            chart.add(point);
        }
        return chart;
    }
}
