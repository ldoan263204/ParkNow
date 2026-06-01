package vn.edu.stu.dh52201042_parknow_backend.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import vn.edu.stu.dh52201042_parknow_backend.model.User;
import vn.edu.stu.dh52201042_parknow_backend.security.JwtUtil;
import vn.edu.stu.dh52201042_parknow_backend.service.UserService;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/users")
@CrossOrigin(origins = "*")
public class UserController {

    @Autowired
    private UserService userService;

    @Autowired
    private JwtUtil jwtUtil;

    // --------------------------------------------------------
    // ADMIN: Lấy danh sách tất cả người dùng
    // --------------------------------------------------------
    @GetMapping
    public List<User> getAllUsers() {
        return userService.getAllUsers();
    }

    @GetMapping("/{id}")
    public ResponseEntity<User> getUserById(@PathVariable Long id) {
        return userService.getUserById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    // --------------------------------------------------------
    // ĐĂNG KÝ
    // --------------------------------------------------------
    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody User user) {
        try {
            User newUser = userService.register(user);
            // Tạo token ngay sau khi đăng ký thành công
            String token = jwtUtil.generateToken(newUser.getEmail(), newUser.getRole());
            return ResponseEntity.ok(buildAuthResponse(newUser, token));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // --------------------------------------------------------
    // ĐĂNG NHẬP — Trả về JWT + thông tin User
    // --------------------------------------------------------
    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody Map<String, String> credentials) {
        String email    = credentials.get("email");
        String password = credentials.get("password");

        return userService.login(email, password)
                .map(user -> {
                    // Tạo JWT Token từ email và role
                    String token = jwtUtil.generateToken(user.getEmail(), user.getRole());
                    return ResponseEntity.ok(buildAuthResponse(user, token));
                })
                .orElse(ResponseEntity.status(401)
                        .body(buildError("Email hoặc mật khẩu không đúng!")));
    }

    // --------------------------------------------------------
    // CẬP NHẬT THÔNG TIN (yêu cầu token hợp lệ)
    // --------------------------------------------------------
    @PutMapping("/{id}")
    public ResponseEntity<?> updateUser(@PathVariable Long id, @RequestBody User user) {
        try {
            User updated = userService.updateUser(id, user);
            return ResponseEntity.ok(updated);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(buildError(e.getMessage()));
        }
    }

    // --------------------------------------------------------
    // TÌM THEO MÃ NHÂN VIÊN
    // --------------------------------------------------------
    @GetMapping("/by-staff-code/{code}")
    public ResponseEntity<?> getByStaffCode(@PathVariable String code) {
        return userService.getAllUsers().stream()
                .filter(u -> code.equals(u.getStaffCode()))
                .findFirst()
                .<ResponseEntity<?>>map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    // --------------------------------------------------------
    // XÓA TÀI KHOẢN (chỉ ADMIN)
    // --------------------------------------------------------
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteUser(@PathVariable Long id) {
        userService.deleteUser(id);
        return ResponseEntity.noContent().build();
    }

    // --------------------------------------------------------
    // Helper: Tạo response body thống nhất cho login/register
    // --------------------------------------------------------
    private Map<String, Object> buildAuthResponse(User user, String token) {
        Map<String, Object> resp = new LinkedHashMap<>();
        resp.put("token",     token);
        resp.put("tokenType", "Bearer");
        resp.put("id",        user.getId());
        resp.put("email",     user.getEmail());
        resp.put("fullName",  user.getFullName());
        resp.put("phone",     user.getPhone());
        resp.put("role",      user.getRole());
        resp.put("avatarUrl", user.getAvatarUrl());
        resp.put("staffCode", user.getStaffCode());   // null cho CUSTOMER/ADMIN
        return resp;
    }

    private Map<String, Object> buildError(String message) {
        return Map.of("error", message);
    }
}
