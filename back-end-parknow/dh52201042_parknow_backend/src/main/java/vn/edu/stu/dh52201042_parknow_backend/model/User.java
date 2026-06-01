package vn.edu.stu.dh52201042_parknow_backend.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.time.LocalDateTime;

@Entity
@Table(name = "users")
@Getter
@Setter
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true, nullable = false)
    private String email;

    @Column(name = "password", nullable = false)
    private String password;

    @Column(name = "full_name")
    private String fullName;

    private String phone;

    // Vai trò: CUSTOMER, STAFF, ADMIN
    @Column(nullable = false)
    private String role;

    @Column(name = "avatar_url")
    private String avatarUrl;

    /**
     * Mã nhân viên — tự động sinh khi role = STAFF.
     * Format: STAFF_001, STAFF_002, ...
     * Null với CUSTOMER và ADMIN.
     */
    @Column(name = "staff_code", unique = true)
    private String staffCode;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
}

