import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../config/app_colors.dart';
import '../../../config/measures.dart';
import '../../../core/secure_storage.dart';
import '../../../models/booking_models.dart';
import '../../../models/core/app_enums.dart';
import '../../../models/user_models.dart';
import '../../../services/booking_service.dart';
import '../../../services/user_service.dart';
import 'buy_service.dart';
import '../profile.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  final UserService _userService = UserService();
  final BookingService _bookingService = BookingService();

  bool _isLoading = true;
  String? _errorMessage;

  UserResponseDto? _currentUser;
  List<BookingResponseDto> _bookings = const <BookingResponseDto>[];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _userService.dispose();
    _bookingService.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await SecureStorage.getToken();
      if (token == null || token.isEmpty) {
        throw const UserServiceException('No se encontro la sesion del usuario.');
      }

      final email = SecureStorage.getEmailFromToken(token).trim().toLowerCase();
      final usersResponse = await _userService.getAllUsers();
      final users = usersResponse.data ?? <UserResponseDto>[];

      UserResponseDto? currentUser;
      for (final user in users) {
        if (user.email.trim().toLowerCase() == email) {
          currentUser = user;
          break;
        }
      }

      if (currentUser == null || currentUser.id == null) {
        throw const UserServiceException(
          'No se pudo cargar el usuario autenticado.',
        );
      }

      final bookingsResponse = await _bookingService.getBookingsByUser(
        currentUser.id!,
      );

      final bookings = (bookingsResponse.data ?? <BookingResponseDto>[])
          .where((booking) => booking.state != StateBooking.canceled)
          .toList()
        ..sort((first, second) {
          final firstDate = first.dateBooking ?? DateTime(2100);
          final secondDate = second.dateBooking ?? DateTime(2100);
          final dateComparison = firstDate.compareTo(secondDate);
          if (dateComparison != 0) {
            return dateComparison;
          }
          return (first.startTime ?? '').compareTo(second.startTime ?? '');
        });

      if (!mounted) return;

      setState(() {
        _currentUser = currentUser;
        _bookings = bookings;
        _isLoading = false;
      });
    } on UserServiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } on BookingServiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'No se pudo cargar la pantalla del cliente.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = Measures.scale(context);
    final userName = (_currentUser?.fullName.trim().isNotEmpty ?? false)
        ? _currentUser!.fullName.trim()
        : 'Nombre usuario';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.turquoise,
          onRefresh: _loadData,
          child: _buildBody(context, scale, userName),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            28 * scale,
            10 * scale,
            28 * scale,
            18 * scale,
          ),
          child: SizedBox(
            height: 52 * scale,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const BuyServiceScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.turquoise,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24 * scale),
                ),
              ),
              child: Text(
                'Contratar ayuda',
                style: TextStyle(
                  fontSize: 20 * scale,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, double scale, String userName) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.turquoise),
      );
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(24 * scale),
        children: [
          SizedBox(height: 100 * scale),
          _InfoMessageCard(
            title: 'No se pudo cargar la pantalla',
            message: _errorMessage!,
            actionLabel: 'Reintentar',
            onPressed: _loadData,
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: EdgeInsets.fromLTRB(
        20 * scale,
        16 * scale,
        20 * scale,
        32 * scale,
      ),
      children: [
        _TopProfileButton(
          userName: userName,
          scale: scale,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
            );
          },
        ),
        SizedBox(height: 14 * scale),
        SvgPicture.asset(
          'assets/images/client_image_home.svg',
          height: 250 * scale,
          fit: BoxFit.contain,
        ),
        SizedBox(height: 6 * scale),
        Text(
          'Buenos dias, ${_firstName(userName)}',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28 * scale,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF6F8FAF),
          ),
        ),
        SizedBox(height: 18 * scale),
        Text(
          'Servicios contratados para hoy',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18 * scale,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF434343),
          ),
        ),
        SizedBox(height: 16 * scale),
        if (_bookings.isEmpty)
          const _InfoMessageCard(
            title: 'No hay reservas disponibles',
            message: 'Cuando tengas reservas contratadas apareceran aqui.',
          )
        else
          ..._bookings.map(
            (booking) => Padding(
              padding: EdgeInsets.only(bottom: 14 * scale),
              child: _BookingCard(
                booking: booking,
                scale: scale,
              ),
            ),
          ),
      ],
    );
  }

  String _firstName(String fullName) {
    final pieces = fullName.trim().split(RegExp(r'\s+'));
    if (pieces.isEmpty || pieces.first.isEmpty) {
      return 'Jesus';
    }
    return pieces.first;
  }
}

class _TopProfileButton extends StatelessWidget {
  const _TopProfileButton({
    required this.userName,
    required this.scale,
    required this.onTap,
  });

  final String userName;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFE4E4E4),
      borderRadius: BorderRadius.circular(22 * scale),
      child: InkWell(
        borderRadius: BorderRadius.circular(22 * scale),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 10 * scale,
            vertical: 8 * scale,
          ),
          child: Row(
            children: [
              Container(
                width: 28 * scale,
                height: 28 * scale,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_circle_outlined,
                  color: AppColors.turquoise,
                  size: 22 * scale,
                ),
              ),
              SizedBox(width: 12 * scale),
              Expanded(
                child: Text(
                  userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF4A4A4A),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.scale,
  });

  final BookingResponseDto booking;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF8DB0D3),
        borderRadius: BorderRadius.circular(20 * scale),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: 14 * scale,
        vertical: 12 * scale,
      ),
      child: Row(
        children: [
          Icon(
            Icons.account_circle_outlined,
            color: AppColors.navyBlue,
            size: 32 * scale,
          ),
          SizedBox(width: 12 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reserva #${booking.id ?? '-'}',
                  style: TextStyle(
                    fontSize: 16 * scale,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1B3D5D),
                  ),
                ),
                SizedBox(height: 6 * scale),
                _BookingMetaRow(
                  icon: Icons.access_time_outlined,
                  text: _timeRangeLabel(booking),
                  scale: scale,
                ),
                SizedBox(height: 3 * scale),
                _BookingMetaRow(
                  icon: Icons.calendar_today_outlined,
                  text: _dateLabel(booking.dateBooking),
                  scale: scale,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _dateLabel(DateTime? date) {
    if (date == null) {
      return 'Fecha pendiente';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  String _timeRangeLabel(BookingResponseDto booking) {
    final startTime = _shortTime(booking.startTime);
    final endTime = _shortTime(booking.endTime);
    return '$startTime - $endTime';
  }

  String _shortTime(String? value) {
    if (value == null || value.isEmpty) {
      return '--:--';
    }
    return value.length >= 5 ? value.substring(0, 5) : value;
  }
}

class _BookingMetaRow extends StatelessWidget {
  const _BookingMetaRow({
    required this.icon,
    required this.text,
    required this.scale,
  });

  final IconData icon;
  final String text;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 12 * scale,
          color: AppColors.navyBlue,
        ),
        SizedBox(width: 5 * scale),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12 * scale,
              color: const Color(0xFF3D6E94),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoMessageCard extends StatelessWidget {
  const _InfoMessageCard({
    required this.title,
    required this.message,
    this.actionLabel,
    this.onPressed,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scale = Measures.scale(context);

    return Container(
      padding: EdgeInsets.all(18 * scale),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FB),
        borderRadius: BorderRadius.circular(18 * scale),
        border: Border.all(color: const Color(0xFFD7E5F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16 * scale,
              fontWeight: FontWeight.w700,
              color: AppColors.navyBlue,
            ),
          ),
          SizedBox(height: 8 * scale),
          Text(
            message,
            style: TextStyle(
              fontSize: 13 * scale,
              color: const Color(0xFF5E6F7E),
            ),
          ),
          if (actionLabel != null && onPressed != null) ...[
            SizedBox(height: 14 * scale),
            SizedBox(
              height: 40 * scale,
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.turquoise,
                  foregroundColor: Colors.white,
                ),
                child: Text(actionLabel!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
