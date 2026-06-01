import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:dh52201042_parknow/features/authentication/services/auth_service.dart';
import 'package:dh52201042_parknow/features/authentication/models/user_model.dart';
import 'package:dh52201042_parknow/features/authentication/viewmodels/auth_viewmodel.dart';

class MockAuthService extends Mock implements AuthService {
  @override
  Future<UserModel> login(String? email, String? password) {
    return super.noSuchMethod(
      Invocation.method(#login, [email, password]),
      returnValue: Future<UserModel>.value(
        UserModel(
          id: 1,
          email: email ?? 'test@example.com',
          fullName: 'Test User',
          phone: '0123456789',
          role: 'CUSTOMER',
          token: 'mock-jwt-token',
        ),
      ),
      returnValueForMissingStub: Future<UserModel>.value(
        UserModel(
          id: 1,
          email: email ?? 'test@example.com',
          fullName: 'Test User',
          phone: '0123456789',
          role: 'CUSTOMER',
          token: 'mock-jwt-token',
        ),
      ),
    ) as Future<UserModel>;
  }

  @override
  Future<UserModel> register({
    String? email,
    String? password,
    String? fullName,
    String? phone,
    String? role,
  }) {
    return super.noSuchMethod(
      Invocation.method(#register, [], {
        #email: email,
        #password: password,
        #fullName: fullName,
        #phone: phone,
        #role: role,
      }),
      returnValue: Future<UserModel>.value(
        UserModel(
          id: 1,
          email: email ?? 'test@example.com',
          fullName: fullName ?? 'Test User',
          phone: phone ?? '0123456789',
          role: role ?? 'CUSTOMER',
          token: 'mock-jwt-token',
        ),
      ),
      returnValueForMissingStub: Future<UserModel>.value(
        UserModel(
          id: 1,
          email: email ?? 'test@example.com',
          fullName: fullName ?? 'Test User',
          phone: phone ?? '0123456789',
          role: role ?? 'CUSTOMER',
          token: 'mock-jwt-token',
        ),
      ),
    ) as Future<UserModel>;
  }
}

void main() {
  late MockAuthService mockAuthService;
  late AuthViewModel authViewModel;

  setUp(() {
    mockAuthService = MockAuthService();
    authViewModel = AuthViewModel(service: mockAuthService);
  });

  group('AuthViewModel Unit Tests', () {
    test('Initial state is correct', () {
      expect(authViewModel.user, isNull);
      expect(authViewModel.isLoading, isFalse);
      expect(authViewModel.errorMessage, isEmpty);
      expect(authViewModel.isLoggedIn, isFalse);
    });

    test('Login success updates user and loading status', () async {
      const email = 'test@example.com';
      const password = 'password123';

      when(mockAuthService.login(email, password)).thenAnswer(
        (_) => Future.value(
          UserModel(
            id: 42,
            email: email,
            fullName: 'Success User',
            phone: '0123456789',
            role: 'CUSTOMER',
            token: 'success-token',
          ),
        ),
      );

      final result = await authViewModel.login(email, password);

      expect(result, isTrue);
      expect(authViewModel.isLoading, isFalse);
      expect(authViewModel.user, isNotNull);
      expect(authViewModel.user!.email, email);
      expect(authViewModel.user!.fullName, 'Success User');
      expect(authViewModel.user!.token, 'success-token');
      expect(authViewModel.errorMessage, isEmpty);
      verify(mockAuthService.login(email, password)).called(1);
    });

    test('Login failure sets error message and loading status', () async {
      const email = 'wrong@example.com';
      const password = 'wrongpassword';

      when(mockAuthService.login(email, password))
          .thenThrow(Exception('Sai tài khoản hoặc mật khẩu!'));

      final result = await authViewModel.login(email, password);

      expect(result, isFalse);
      expect(authViewModel.isLoading, isFalse);
      expect(authViewModel.user, isNull);
      expect(authViewModel.errorMessage, 'Sai tài khoản hoặc mật khẩu!');
      verify(mockAuthService.login(email, password)).called(1);
    });

    test('Register success updates user and loading status', () async {
      const email = 'new@example.com';
      const password = 'newpassword';
      const fullName = 'New Register';
      const phone = '0987654321';
      const role = 'CUSTOMER';

      when(
        mockAuthService.register(
          email: email,
          password: password,
          fullName: fullName,
          phone: phone,
          role: role,
        ),
      ).thenAnswer(
        (_) => Future.value(
          UserModel(
            id: 99,
            email: email,
            fullName: fullName,
            phone: phone,
            role: role,
            token: 'new-token',
          ),
        ),
      );

      final result = await authViewModel.register(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        role: role,
      );

      expect(result, isTrue);
      expect(authViewModel.isLoading, isFalse);
      expect(authViewModel.user, isNotNull);
      expect(authViewModel.user!.email, email);
      expect(authViewModel.user!.fullName, fullName);
      expect(authViewModel.errorMessage, isEmpty);
      verify(
        mockAuthService.register(
          email: email,
          password: password,
          fullName: fullName,
          phone: phone,
          role: role,
        ),
      ).called(1);
    });

    test('Register failure sets error message and loading status', () async {
      const email = 'existing@example.com';
      const password = 'password';
      const fullName = 'Existing User';
      const phone = '0123456789';
      const role = 'CUSTOMER';

      when(
        mockAuthService.register(
          email: email,
          password: password,
          fullName: fullName,
          phone: phone,
          role: role,
        ),
      ).thenThrow(Exception('Email đã được sử dụng!'));

      final result = await authViewModel.register(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        role: role,
      );

      expect(result, isFalse);
      expect(authViewModel.isLoading, isFalse);
      expect(authViewModel.user, isNull);
      expect(authViewModel.errorMessage, 'Email đã được sử dụng!');
      verify(
        mockAuthService.register(
          email: email,
          password: password,
          fullName: fullName,
          phone: phone,
          role: role,
        ),
      ).called(1);
    });

    test('Logout clears user status', () async {
      const email = 'test@example.com';
      const password = 'password';

      when(mockAuthService.login(email, password)).thenAnswer(
        (_) => Future.value(
          UserModel(id: 1, email: email, fullName: 'User', phone: '0123456789', role: 'CUSTOMER'),
        ),
      );

      await authViewModel.login(email, password);
      expect(authViewModel.isLoggedIn, isTrue);

      authViewModel.logout();
      expect(authViewModel.isLoggedIn, isFalse);
      expect(authViewModel.user, isNull);
    });
  });
}
