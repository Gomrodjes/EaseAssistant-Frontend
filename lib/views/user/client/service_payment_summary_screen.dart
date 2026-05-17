import 'package:flutter/material.dart';

import '../../../config/app_colors.dart';
import '../../../config/measures.dart';
import '../../../models/models.dart';
import '../../../services/booking_service.dart';
import '../../../services/payment_service.dart';
import 'client_home_screen.dart';

class ServicePaymentSummaryScreen extends StatefulWidget {
  const ServicePaymentSummaryScreen({
    super.key,
    required this.selection,
  });

  final ServiceBookingSelection selection;

  @override
  State<ServicePaymentSummaryScreen> createState() =>
      _ServicePaymentSummaryScreenState();
}

class _ServicePaymentSummaryScreenState
    extends State<ServicePaymentSummaryScreen> {
  static const double _commissionPercentage = 10;

  final BookingService _bookingService = BookingService();
  final PaymentService _paymentService = PaymentService();

  bool _isProcessing = false;
  int? _createdBookingId;
  int? _createdPaymentId;

  @override
  void dispose() {
    _bookingService.dispose();
    _paymentService.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    final assistantId = widget.selection.assistant.id;
    final customerId = widget.selection.customer.id;
    final jobId = widget.selection.job.id;
    final addressId = widget.selection.address.id;
    final price = widget.selection.job.price;

    if (assistantId == null ||
        customerId == null ||
        jobId == null ||
        addressId == null ||
        price == null) {
      _showMessage('Faltan datos para completar la reserva.');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      var bookingId = _createdBookingId;
      if (bookingId == null) {
        final bookingResponse = await _bookingService.createBooking(
          BookingSaveDto(
            dateBooking: widget.selection.serviceDate,
            startTime: widget.selection.startTime,
            clientNote: widget.selection.note.trim().isEmpty
                ? null
                : widget.selection.note.trim(),
            customerId: customerId,
            workerId: assistantId,
            jobId: jobId,
            addressId: addressId,
          ),
        );

        bookingId = bookingResponse.data?.id;
        if (bookingId == null) {
          throw const BookingServiceException(
            'No se pudo crear la reserva final.',
          );
        }
        _createdBookingId = bookingId;
      }

      var paymentId = _createdPaymentId;
      if (paymentId == null) {
        final paymentResponse = await _paymentService.createPayment(
          PaymentSaveDto(
            amount: price,
            commissionPercentage: _commissionPercentage,
            bookingId: bookingId,
            stripePaymentId: null,
          ),
        );

        paymentId = paymentResponse.data?.id;
        if (paymentId == null) {
          throw const PaymentServiceException(
            'No se pudo crear el pago simulado.',
          );
        }
        _createdPaymentId = paymentId;
      }

      final fakePaymentId =
          'SIM-$bookingId-${DateTime.now().millisecondsSinceEpoch}';

      await _paymentService.updatePayment(
        paymentId,
        PaymentUpdateDto(
          state: StatePayment.paid,
          stripePaymentId: fakePaymentId,
        ),
      );

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          final scale = Measures.scale(dialogContext);
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22 * scale),
            ),
            title: const Text('Reserva confirmada'),
            content: const Text(
              'El pago se ha simulado correctamente y la reserva ya esta creada.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Aceptar'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => const ClientHomeScreen(),
        ),
        (route) => false,
      );
    } on BookingServiceException catch (e) {
      if (!mounted) return;
      _showMessage(e.message);
    } on PaymentServiceException catch (e) {
      if (!mounted) return;
      _showMessage(e.message);
    } catch (_) {
      if (!mounted) return;
      _showMessage('No se pudo completar el pago simulado.');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = Measures.scale(context);
    final price = widget.selection.job.price ?? 0;
    final serviceFee = 0.0;
    final total = price + serviceFee;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.navyBlue,
        elevation: 0,
        title: const Text('Confirmacion final'),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          22 * scale,
          12 * scale,
          22 * scale,
          28 * scale,
        ),
        children: [
          _SummaryLine(
            icon: Icons.near_me_disabled_outlined,
            title: 'Encontrarse en :',
            value: _addressLabel(widget.selection.address),
            scale: scale,
          ),
          _SummaryLine(
            icon: Icons.highlight_off,
            title: 'Telefono :',
            value: widget.selection.assistant.phoneNumber.trim().isEmpty
                ? 'Sin telefono disponible'
                : widget.selection.assistant.phoneNumber.trim(),
            scale: scale,
          ),
          _SummaryLine(
            icon: Icons.access_time_outlined,
            title: 'Hora del servicio:',
            value:
                '${_formatDate(widget.selection.serviceDate)} - ${widget.selection.startTime.substring(0, 5)} a ${widget.selection.endTime.substring(0, 5)}',
            scale: scale,
            showDivider: false,
          ),
          SizedBox(height: 20 * scale),
          Text(
            'Resumen del pedido',
            style: TextStyle(
              fontSize: 22 * scale,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF222222),
            ),
          ),
          SizedBox(height: 18 * scale),
          Row(
            children: [
              Icon(
                Icons.account_circle_outlined,
                size: 36 * scale,
                color: AppColors.navyBlue,
              ),
              SizedBox(width: 12 * scale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.selection.assistant.fullName,
                      style: TextStyle(
                        fontSize: 18 * scale,
                        color: const Color(0xFF2A2A2A),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8 * scale),
                    Text(
                      'Te ayudara con ${widget.selection.job.name}',
                      style: TextStyle(
                        fontSize: 16 * scale,
                        color: const Color(0xFF383838),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 18 * scale),
          Divider(color: const Color(0xFF90B5D6), thickness: 1),
          SizedBox(height: 12 * scale),
          _PriceRow(label: 'Subtotal', amount: price, scale: scale),
          SizedBox(height: 8 * scale),
          _PriceRow(
            label: 'Servicio',
            amount: serviceFee,
            scale: scale,
          ),
          SizedBox(height: 10 * scale),
          _PriceRow(
            label: 'Total',
            amount: total,
            scale: scale,
            highlight: true,
          ),
          SizedBox(height: 24 * scale),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 14 * scale,
              vertical: 16 * scale,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18 * scale),
              border: Border.all(color: const Color(0xFFB7D4EA)),
              color: const Color(0xFFF8FBFD),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Metodo de pago simulado',
                    style: TextStyle(
                      fontSize: 16 * scale,
                      color: const Color(0xFF2D2D2D),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.navyBlue,
                  size: 24 * scale,
                ),
              ],
            ),
          ),
          SizedBox(height: 24 * scale),
          SizedBox(
            height: 50 * scale,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _pay,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8DB0D3),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18 * scale),
                ),
              ),
              child: _isProcessing
                  ? SizedBox(
                      width: 20 * scale,
                      height: 20 * scale,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Pagar',
                      style: TextStyle(
                        fontSize: 18 * scale,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          SizedBox(height: 12 * scale),
          SizedBox(
            height: 50 * scale,
            child: OutlinedButton(
              onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF8DB0D3),
                side: const BorderSide(color: Color(0xFF8DB0D3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18 * scale),
                ),
              ),
              child: Text(
                'Volver',
                style: TextStyle(
                  fontSize: 16 * scale,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _addressLabel(AddressResponseDto address) {
    final description = address.description?.trim();
    final base =
        '${address.street}, ${address.city} ${address.zipCode}, ${address.country}';
    if (description == null || description.isEmpty) {
      return base;
    }
    return '$base\n$description';
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    return '$day/$month/$year';
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.icon,
    required this.title,
    required this.value,
    required this.scale,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final String value;
  final double scale;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16 * scale),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 22 * scale,
                color: const Color(0xFF151515),
              ),
              SizedBox(width: 10 * scale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16 * scale,
                        color: const Color(0xFF252525),
                      ),
                    ),
                    SizedBox(height: 4 * scale),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 13 * scale,
                        color: const Color(0xFF5C5C5C),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (showDivider) ...[
            SizedBox(height: 10 * scale),
            Divider(color: const Color(0xFF90B5D6), thickness: 1),
          ],
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.amount,
    required this.scale,
    this.highlight = false,
  });

  final String label;
  final double amount;
  final double scale;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final color = highlight ? AppColors.navyBlue : const Color(0xFF5C5C5C);
    final weight = highlight ? FontWeight.w700 : FontWeight.w400;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14 * scale,
              color: color,
              fontWeight: weight,
            ),
          ),
        ),
        Text(
          '${amount.toStringAsFixed(2)} EUR',
          style: TextStyle(
            fontSize: 14 * scale,
            color: color,
            fontWeight: weight,
          ),
        ),
      ],
    );
  }
}
