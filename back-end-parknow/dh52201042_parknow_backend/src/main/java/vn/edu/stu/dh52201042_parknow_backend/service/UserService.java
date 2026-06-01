package vn.edu.stu.dh52201042_parknow_backend.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import vn.edu.stu.dh52201042_parknow_backend.model.User;
import vn.edu.stu.dh52201042_parknow_backend.repository.UserRepository;

import java.util.List;
import java.util.Optional;

@Service
public class UserService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    public List<User> getAllUsers() {
        return userRepository.findAll();
    }

    public Optional<User> getUserById(Long id) {
        return userRepository.findById(id);
    }

    public Optional<User> getUserByEmail(String email) {
        return userRepository.findByEmail(email);
    }

    /**
     * Đăng ký tài khoản mới.
     * - Mật khẩu được hash bằng BCrypt.
     * - Nếu role = STAFF → tự động sinh staffCode duy nhất (STAFF_001, STAFF_002...).
     */
    public User register(User user) {
        if (userRepository.existsByEmail(user.getEmail())) {
            throw new RuntimeException("Email đã được sử dụng!");
        }

        // Hash mật khẩu
        user.setPassword(passwordEncoder.encode(user.getPassword()));

        // Tự động sinh staffCode nếu là nhân viên
        if ("STAFF".equalsIgnoreCase(user.getRole())) {
            user.setStaffCode(generateUniqueStaffCode());
        }

        return userRepository.save(user);
    }

    /**
     * Sinh staffCode duy nhất theo format STAFF_XXX.
     * Đếm tổng số STAFF hiện có và tăng dần để đảm bảo không trùng.
     */
    private String generateUniqueStaffCode() {
        long staffCount = userRepository.countByRole("STAFF");
        String code;
        do {
            staffCount++;
            code = String.format("STAFF_%03d", staffCount);
        } while (userRepository.findByStaffCode(code).isPresent());
        return code;
    }

    /**
     * Đăng nhập: tìm user theo email, verify mật khẩu bằng BCrypt.
     */
    public Optional<User> login(String email, String password) {
        return userRepository.findByEmail(email)
                .filter(user -> passwordEncoder.matches(password, user.getPassword()));
    }

    /**
     * Cập nhật thông tin user (Admin có thể đổi role, fullName, phone).
     * Nếu role đổi sang STAFF và chưa có staffCode → tự sinh mã mới.
     * Nếu role đổi khỏi STAFF → xóa staffCode.
     */
    public User updateUser(Long id, User updatedUser) {
        return userRepository.findById(id).map(user -> {
            if (updatedUser.getFullName() != null)  user.setFullName(updatedUser.getFullName());
            if (updatedUser.getPhone()    != null)  user.setPhone(updatedUser.getPhone());
            if (updatedUser.getAvatarUrl()!= null)  user.setAvatarUrl(updatedUser.getAvatarUrl());

            // Cho phép Admin đổi role
            if (updatedUser.getRole() != null && !updatedUser.getRole().isBlank()) {
                String newRole = updatedUser.getRole().toUpperCase();
                String oldRole = user.getRole();
                user.setRole(newRole);

                // Nếu nâng lên STAFF và chưa có staffCode → sinh mã
                if ("STAFF".equals(newRole) && user.getStaffCode() == null) {
                    user.setStaffCode(generateUniqueStaffCode());
                }
                // Nếu không còn là STAFF → xóa staffCode
                if (!"STAFF".equals(newRole) && "STAFF".equals(oldRole)) {
                    user.setStaffCode(null);
                }
            }

            // Đổi mật khẩu (nếu có)
            if (updatedUser.getPassword() != null && !updatedUser.getPassword().isBlank()) {
                user.setPassword(passwordEncoder.encode(updatedUser.getPassword()));
            }

            return userRepository.save(user);
        }).orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng với ID: " + id));
    }

    public void deleteUser(Long id) {
        userRepository.deleteById(id);
    }
}
