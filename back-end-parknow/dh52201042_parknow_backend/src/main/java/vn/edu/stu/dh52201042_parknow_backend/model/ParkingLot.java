package vn.edu.stu.dh52201042_parknow_backend.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.math.BigDecimal;

@Entity
@Table(name = "parking_lots")
@Getter
@Setter
public class ParkingLot {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // Bổ sung owner_id (Dùng Long vì thường ID người dùng là số nguyên lớn)
    @Column(name = "owner_id")
    private Long ownerId;

    private String name;
    private String address;
    private BigDecimal latitude;
    private BigDecimal longitude;

    @Column(name = "total_slots")
    private Integer totalSlots;

    @Column(name = "available_slots")
    private Integer availableSlots;

    @Column(name = "price_per_hour")
    private BigDecimal pricePerHour;

    private String status;

    // Bổ sung luôn rejection_reason cho đủ bộ theo đúng hình của bạn
    @Column(name = "rejection_reason")
    private String rejectionReason;
}