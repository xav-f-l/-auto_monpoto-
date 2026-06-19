import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/bookings/models/booking_model.dart';
import '../../features/vehicles/models/vehicle_model.dart';
import '../../features/auth/models/user_model.dart';

class ReceiptService {
  static Future<Uint8List> generateReceipt({
    required BookingModel booking,
    required VehicleModel vehicle,
    required UserModel user,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildHeader(),
          pw.SizedBox(height: 20),
          _buildTitle(),
          pw.SizedBox(height: 24),
          _buildInfoRow('N° réservation', '#${booking.id.substring(0, 8)}'),
          _buildInfoRow('Client', user.fullName),
          _buildInfoRow('Email', user.email),
          _buildInfoRow('Téléphone', user.phone),
          pw.SizedBox(height: 16),
          pw.Divider(),
          pw.SizedBox(height: 16),
          _buildSectionTitle('Véhicule'),
          pw.SizedBox(height: 8),
          _buildInfoRow('Véhicule', vehicle.fullName),
          _buildInfoRow('Année', '${vehicle.year}'),
          _buildInfoRow('Prix journalier',
              '${vehicle.pricePerDay.toStringAsFixed(0)} FCFA'),
          pw.SizedBox(height: 16),
          pw.Divider(),
          pw.SizedBox(height: 16),
          _buildSectionTitle('Période de location'),
          pw.SizedBox(height: 8),
          _buildInfoRow('Départ',
              '${booking.startDate.day}/${booking.startDate.month}/${booking.startDate.year}'),
          _buildInfoRow('Retour',
              '${booking.endDate.day}/${booking.endDate.month}/${booking.endDate.year}'),
          _buildInfoRow('Durée', '${booking.numberOfDays} jour(s)'),
          if (booking.pickupLocation != null)
            _buildInfoRow('Lieu de prise en charge', booking.pickupLocation!),
          pw.SizedBox(height: 24),
          pw.Divider(thickness: 2),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('TOTAL PAYÉ',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  )),
              pw.Text('${booking.totalAmount.toStringAsFixed(0)} FCFA',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue,
                  )),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Divider(),
          pw.SizedBox(height: 24),
          pw.Center(
            child: pw.Text(
              'Merci pour votre confiance !',
              style: pw.TextStyle(
                fontSize: 14,
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Text(
              'Auto Monpoto - Location de véhicules',
              style: pw.TextStyle(
                fontSize: 11,
                color: PdfColors.grey500,
              ),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text(
              'BP 1234 Libreville, Gabon',
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey400,
              ),
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('AUTO MONPOTO',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                )),
            pw.Text('Location de véhicules',
                style: pw.TextStyle(
                    fontSize: 10, color: PdfColors.grey600)),
          ],
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.blue300),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Text('RECU',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              )),
        ),
      ],
    );
  }

  static pw.Widget _buildTitle() {
    return pw.Center(
      child: pw.Text(
        'REÇU DE PAIEMENT',
        style: pw.TextStyle(
          fontSize: 22,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blue900,
        ),
      ),
    );
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 14,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.blue700,
      ),
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: const pw.TextStyle(
                fontSize: 12,
                color: PdfColors.grey700,
              )),
          pw.Text(value,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              )),
        ],
      ),
    );
  }

  static Future<void> saveAndOpen(Uint8List bytes) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/recu_auto_monpoto.pdf');
    await file.writeAsBytes(bytes);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'recu_auto_monpoto.pdf',
    );
  }
}
