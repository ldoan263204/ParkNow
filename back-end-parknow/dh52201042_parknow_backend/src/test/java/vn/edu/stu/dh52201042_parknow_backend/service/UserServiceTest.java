package vn.edu.stu.dh52201042_parknow_backend.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.security.crypto.password.PasswordEncoder;
import vn.edu.stu.dh52201042_parknow_backend.model.User;
import vn.edu.stu.dh52201042_parknow_backend.repository.UserRepository;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class UserServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @InjectMocks
    private UserService userService;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    void testRegisterCustomer_Success() {
        User customer = new User();
        customer.setEmail("customer@test.com");
        customer.setPassword("plainPassword");
        customer.setRole("CUSTOMER");

        when(userRepository.existsByEmail(customer.getEmail())).thenReturn(false);
        when(passwordEncoder.encode(customer.getPassword())).thenReturn("encodedPassword");
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> invocation.getArgument(0));

        User registered = userService.register(customer);

        assertNotNull(registered);
        assertEquals("encodedPassword", registered.getPassword());
        assertNull(registered.getStaffCode());
        verify(userRepository, times(1)).save(customer);
    }

    @Test
    void testRegisterStaff_GeneratesStaffCode() {
        User staff = new User();
        staff.setEmail("staff@test.com");
        staff.setPassword("plainPassword");
        staff.setRole("STAFF");

        when(userRepository.existsByEmail(staff.getEmail())).thenReturn(false);
        when(passwordEncoder.encode(staff.getPassword())).thenReturn("encodedPassword");
        when(userRepository.countByRole("STAFF")).thenReturn(0L);
        when(userRepository.findByStaffCode("STAFF_001")).thenReturn(Optional.empty());
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> invocation.getArgument(0));

        User registered = userService.register(staff);

        assertNotNull(registered);
        assertEquals("encodedPassword", registered.getPassword());
        assertEquals("STAFF_001", registered.getStaffCode());
        verify(userRepository, times(1)).save(staff);
    }

    @Test
    void testRegisterEmailAlreadyExists_ThrowsException() {
        User user = new User();
        user.setEmail("exists@test.com");

        when(userRepository.existsByEmail(user.getEmail())).thenReturn(true);

        RuntimeException exception = assertThrows(RuntimeException.class, () -> userService.register(user));
        assertEquals("Email đã được sử dụng!", exception.getMessage());
        verify(userRepository, never()).save(any(User.class));
    }

    @Test
    void testUpdateUserRoleToStaff_GeneratesStaffCode() {
        User existingUser = new User();
        existingUser.setId(1L);
        existingUser.setRole("CUSTOMER");
        existingUser.setStaffCode(null);

        User updates = new User();
        updates.setRole("STAFF");

        when(userRepository.findById(1L)).thenReturn(Optional.of(existingUser));
        when(userRepository.countByRole("STAFF")).thenReturn(5L);
        when(userRepository.findByStaffCode("STAFF_006")).thenReturn(Optional.empty());
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> invocation.getArgument(0));

        User updated = userService.updateUser(1L, updates);

        assertNotNull(updated);
        assertEquals("STAFF", updated.getRole());
        assertEquals("STAFF_006", updated.getStaffCode());
    }

    @Test
    void testUpdateUserRoleFromStaffToCustomer_RemovesStaffCode() {
        User existingUser = new User();
        existingUser.setId(2L);
        existingUser.setRole("STAFF");
        existingUser.setStaffCode("STAFF_003");

        User updates = new User();
        updates.setRole("CUSTOMER");

        when(userRepository.findById(2L)).thenReturn(Optional.of(existingUser));
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> invocation.getArgument(0));

        User updated = userService.updateUser(2L, updates);

        assertNotNull(updated);
        assertEquals("CUSTOMER", updated.getRole());
        assertNull(updated.getStaffCode());
    }
}
