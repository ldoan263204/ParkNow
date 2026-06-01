package vn.edu.stu.dh52201042_parknow_backend.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import vn.edu.stu.dh52201042_parknow_backend.model.User;
import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByEmail(String email);
    Optional<User> findByEmailAndPassword(String email, String password);
    boolean existsByEmail(String email);

    // Đếm số STAFF hiện có để sinh mã tự động (STAFF_001, STAFF_002, ...)
    long countByRole(String role);

    // Tìm user theo staffCode
    Optional<User> findByStaffCode(String staffCode);
}

