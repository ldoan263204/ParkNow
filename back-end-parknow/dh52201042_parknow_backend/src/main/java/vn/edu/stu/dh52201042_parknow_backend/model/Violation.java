package vn.edu.stu.dh52201042_parknow_backend.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "violations")
@Getter
@Setter
public class Violation {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "parking_lot_id", nullable = false)
    private Long parkingLotId;

    // ID nhân viên báo cáo
    @Column(name = "reported_by")
    private Long reportedBy;

    @Column(name = "vehicle_plate")
    private String vehiclePlate;

    // Lý do vi phạm: wrong_spot | expired | no_ticket | other
    private String reason;

    @Column(name = "image_url")
    private String imageUrl;

    // Trạng thái: pending | resolved
    private String status;

    // ── GIAI ĐOẠN 3: Số tiền phạt và hạn thanh toán ──────────────
    @Column(name = "penalty_amount", precision = 15, scale = 2)
    private BigDecimal penaltyAmount;

    // Thời hạn thanh toán: = createdAt + 30 phút
    @Column(name = "payment_deadline")
    private LocalDateTime paymentDeadline;

    @Column(name = "resolved_at")
    private LocalDateTime resolvedAt;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        if (status == null) {
            status = "pending";
        }
        // Tự động tính tiền phạt mặc định và hạn thanh toán khi tạo mới
        if (penaltyAmount == null) {
            penaltyAmount = BigDecimal.valueOf(200000); // 200.000 đ mặc định
        }
        if (paymentDeadline == null) {
            paymentDeadline = createdAt.plusMinutes(30);
        }
    }
}
