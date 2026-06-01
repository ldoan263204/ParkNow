package vn.edu.stu.dh52201042_parknow_backend.security;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

/**
 * Cấu hình Spring Security:
 * - Tắt CSRF (REST API stateless không cần)
 * - Mở public: POST /api/users/login, POST /api/users/register
 * - Tất cả request khác cần JWT hợp lệ trong header Authorization
 * - Thêm JwtAuthFilter vào filter chain
 */
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Autowired
    private JwtAuthFilter jwtAuthFilter;

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            // Tắt CSRF (không cần với REST + JWT)
            .csrf(AbstractHttpConfigurer::disable)

            // Stateless: không dùng HTTP Session
            .sessionManagement(session ->
                session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))

            // Phân quyền endpoint
            .authorizeHttpRequests(auth -> auth
                // Các endpoint công khai (không cần token)
                .requestMatchers(
                    "/api/users/login",
                    "/api/users/register",
                    "/api/users/by-staff-code/**",
                    "/api/violations",
                    "/api/violations/**",
                    "/api/violations/upload",
                    "/api/parking-lots",
                    "/api/parking-lots/**",
                    "/api/shifts",
                    "/api/shifts/**",
                    "/api/bookings",
                    "/api/bookings/**",
                    "/api/dashboard/**",
                    "/uploads/**",
                    "/error"
                ).permitAll()
                // Tất cả các request khác phải authenticated
                .anyRequest().authenticated()
            )

            // Thêm JwtAuthFilter TRƯỚC filter xác thực mặc định của Spring
            .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    /**
     * BCryptPasswordEncoder để hash mật khẩu khi đăng ký
     * và verify khi đăng nhập.
     */
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}
