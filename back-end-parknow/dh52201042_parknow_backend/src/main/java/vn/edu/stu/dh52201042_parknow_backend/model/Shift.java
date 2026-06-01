package vn.edu.stu.dh52201042_parknow_backend.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "shifts")
@Getter
@Setter
public class Shift {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "staff_id", nullable = false)
    private Long staffId;

    @Column(name = "parking_lot_id", nullable = false)
    private Long parkingLotId;

    @Column(name = "start_time")
    private LocalDateTime startTime;

    @Column(name = "end_time")
    private LocalDateTime endTime;

    // Tổng lượt xe vào
    @Column(name = "total_in")
    private Integer totalIn;

    // Tổng lượt xe ra
    @Column(name = "total_out")
    private Integer totalOut;

    // Doanh thu tiền mặt
    @Column(name = "cash_revenue")
    private BigDecimal cashRevenue;

    // Doanh thu trực tuyến
    @Column(name = "online_revenue")
    private BigDecimal onlineRevenue;

    // Trạng thái: active, completed
    private String status;

    @PrePersist
    protected void onCreate() {
        if (totalIn == null) totalIn = 0;
        if (totalOut == null) totalOut = 0;
        if (cashRevenue == null) cashRevenue = BigDecimal.ZERO;
        if (onlineRevenue == null) onlineRevenue = BigDecimal.ZERO;
        if (status == null) status = "active";
    }
}
