package vn.edu.stu.dh52201042_parknow_backend.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "bookings")
@Getter
@Setter
public class Booking {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "parking_lot_id", nullable = false)
    private Long parkingLotId;

    @Column(name = "vehicle_plate")
    private String vehiclePlate;

    // Loại xe: car, motorbike
    @Column(name = "vehicle_type")
    private String vehicleType;

    @Column(name = "start_time")
    private LocalDateTime startTime;

    @Column(name = "end_time")
    private LocalDateTime endTime;

    // Tổng chi phí: Phí gửi + Phí dịch vụ + Thuế
    @Column(name = "total_cost")
    private BigDecimal totalCost;

    @Column(name = "parking_fee")
    private BigDecimal parkingFee;

    @Column(name = "service_fee")
    private BigDecimal serviceFee;

    @Column(name = "tax")
    private BigDecimal tax;

    // Phương thức thanh toán: momo, card, cash
    @Column(name = "payment_method")
    private String paymentMethod;

    // Trạng thái thanh toán: paid, unpaid
    @Column(name = "payment_status")
    private String paymentStatus;

    // Trạng thái: pending, confirmed, checked_in, completed, cancelled
    private String status;

    @Column(name = "slot_number")
    private String slotNumber;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        if (status == null) {
            status = "pending";
        }
        if (paymentStatus == null) {
            paymentStatus = "unpaid";
        }
    }
}
