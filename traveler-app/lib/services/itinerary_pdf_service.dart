import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/itinerary_model.dart';

/// PDF Generator & Exporter for LocalLens Itineraries
class ItineraryPdfService {
  /// Generate formatted PDF Document from Itinerary
  static Future<Uint8List> generateItineraryPdf(Itinerary itinerary) async {
    final pdf = pw.Document();

    final titleFont = await PdfGoogleFonts.outfitBold();
    final bodyFont = await PdfGoogleFonts.outfitRegular();
    final mediumFont = await PdfGoogleFonts.outfitMedium();

    const primaryColor = PdfColor.fromInt(0xFF0D9488); // Teal
    const darkColor = PdfColor.fromInt(0xFF1E293B);
    const lightBg = PdfColor.fromInt(0xFFF0FDFA);
    const borderColor = PdfColor.fromInt(0xFFE2E8F0);
    const accentOrange = PdfColor.fromInt(0xFFF97316);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 20),
            padding: const pw.EdgeInsets.only(bottom: 12),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: borderColor, width: 1.5),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(
                  children: [
                    pw.Container(
                      width: 32,
                      height: 32,
                      decoration: pw.BoxDecoration(
                        color: primaryColor,
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        'L',
                        style: pw.TextStyle(
                          font: titleFont,
                          color: PdfColors.white,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Local Lens',
                          style: pw.TextStyle(
                            font: titleFont,
                            fontSize: 18,
                            color: primaryColor,
                          ),
                        ),
                        pw.Text(
                          'Personalized AI Travel Itinerary',
                          style: pw.TextStyle(
                            font: bodyFont,
                            fontSize: 10,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Trip Date: ${itinerary.tripDate}',
                      style: pw.TextStyle(
                        font: mediumFont,
                        fontSize: 11,
                        color: darkColor,
                      ),
                    ),
                    pw.Text(
                      'Generated: ${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
                      style: pw.TextStyle(
                        font: bodyFont,
                        fontSize: 9,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 16),
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: borderColor, width: 1),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Local Lens • Explore Like a Local',
                  style: pw.TextStyle(
                    font: bodyFont,
                    fontSize: 9,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: pw.TextStyle(
                    font: bodyFont,
                    fontSize: 9,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          final items = itinerary.items;
          final durationHrs = (itinerary.totalDurationMinutes / 60.0).toStringAsFixed(1);

          return [
            // Destination & Overview Card
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: lightBg,
                borderRadius: pw.BorderRadius.circular(12),
                border: pw.Border.all(color: primaryColor, width: 1.2),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    itinerary.destination,
                    style: pw.TextStyle(
                      font: titleFont,
                      fontSize: 22,
                      color: darkColor,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetricItem('Start Time', itinerary.startTime, mediumFont, bodyFont),
                      _buildMetricItem('End Time', itinerary.endTime, mediumFont, bodyFont),
                      _buildMetricItem('Duration', '$durationHrs hrs', mediumFont, bodyFont),
                      _buildMetricItem('Stops', '${items.length} Places', mediumFont, bodyFont),
                      _buildMetricItem('Est. Cost', 'Rs. ${itinerary.totalEstimatedCost.toInt()}', mediumFont, bodyFont),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Section Title
            pw.Text(
              'Chronological Timeline',
              style: pw.TextStyle(
                font: titleFont,
                fontSize: 16,
                color: darkColor,
              ),
            ),
            pw.SizedBox(height: 12),

            // Timeline Items
            ...items.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final item = entry.value;

              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 12),
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(10),
                  border: pw.Border.all(color: borderColor, width: 1),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Stop Number Badge
                    pw.Container(
                      width: 28,
                      height: 28,
                      decoration: const pw.BoxDecoration(
                        color: primaryColor,
                        shape: pw.BoxShape.circle,
                      ),
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        '$idx',
                        style: pw.TextStyle(
                          font: titleFont,
                          fontSize: 13,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 12),

                    // Details
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Expanded(
                                child: pw.Text(
                                  item.name,
                                  style: pw.TextStyle(
                                    font: titleFont,
                                    fontSize: 14,
                                    color: darkColor,
                                  ),
                                ),
                              ),
                              pw.Container(
                                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: pw.BoxDecoration(
                                  color: lightBg,
                                  borderRadius: pw.BorderRadius.circular(6),
                                  border: pw.Border.all(color: primaryColor, width: 0.8),
                                ),
                                child: pw.Text(
                                  item.timeWindow,
                                  style: pw.TextStyle(
                                    font: mediumFont,
                                    fontSize: 10,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 4),
                          pw.Row(
                            children: [
                              pw.Container(
                                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: pw.BoxDecoration(
                                  color: PdfColor.fromInt(0xFFF1F5F9),
                                  borderRadius: pw.BorderRadius.circular(4),
                                ),
                                child: pw.Text(
                                  item.category,
                                  style: pw.TextStyle(
                                    font: mediumFont,
                                    fontSize: 9,
                                    color: PdfColors.grey800,
                                  ),
                                ),
                              ),
                              pw.SizedBox(width: 8),
                              pw.Expanded(
                                child: pw.Text(
                                  item.location,
                                  maxLines: 1,
                                  style: pw.TextStyle(
                                    font: bodyFont,
                                    fontSize: 10,
                                    color: PdfColors.grey700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (item.description.isNotEmpty) ...[
                            pw.SizedBox(height: 4),
                            pw.Text(
                              item.description,
                              maxLines: 2,
                              style: pw.TextStyle(
                                font: bodyFont,
                                fontSize: 9,
                                color: PdfColors.grey600,
                              ),
                            ),
                          ],
                          pw.SizedBox(height: 6),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                'Duration: ${item.durationMinutes} mins',
                                style: pw.TextStyle(
                                  font: bodyFont,
                                  fontSize: 9,
                                  color: PdfColors.grey700,
                                ),
                              ),
                              pw.Text(
                                'Cost: Rs. ${item.priceInr.toInt()}',
                                style: pw.TextStyle(
                                  font: mediumFont,
                                  fontSize: 10,
                                  color: darkColor,
                                ),
                              ),
                              if (item.travelToNextMinutes > 0)
                                pw.Text(
                                  'Next Transit: ~${item.travelToNextMinutes} mins (${item.travelToNextDistanceKm.toStringAsFixed(1)} km)',
                                  style: pw.TextStyle(
                                    font: mediumFont,
                                    fontSize: 9,
                                    color: accentOrange,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),

            pw.SizedBox(height: 14),

            // Cost Summary Card
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFFF8FAFC),
                borderRadius: pw.BorderRadius.circular(10),
                border: pw.Border.all(color: borderColor, width: 1),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Budget Breakdown',
                    style: pw.TextStyle(
                      font: titleFont,
                      fontSize: 12,
                      color: darkColor,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Experiences & Entry Tickets:', style: pw.TextStyle(font: bodyFont, fontSize: 10, color: PdfColors.grey700)),
                      pw.Text('Rs. ${itinerary.totalSelectedCost.toInt()}', style: pw.TextStyle(font: mediumFont, fontSize: 10, color: darkColor)),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Estimated Transport (Local Lens Rides):', style: pw.TextStyle(font: bodyFont, fontSize: 10, color: PdfColors.grey700)),
                      pw.Text('Rs. ${itinerary.estimatedTransportCost.toInt()}', style: pw.TextStyle(font: mediumFont, fontSize: 10, color: darkColor)),
                    ],
                  ),
                  pw.Divider(color: borderColor, thickness: 1, height: 12),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Total Estimated Day Cost:', style: pw.TextStyle(font: titleFont, fontSize: 11, color: darkColor)),
                      pw.Text('Rs. ${itinerary.totalEstimatedCost.toInt()}', style: pw.TextStyle(font: titleFont, fontSize: 12, color: primaryColor)),
                    ],
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildMetricItem(String label, String value, pw.Font valueFont, pw.Font labelFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            font: labelFont,
            fontSize: 9,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          value,
          style: pw.TextStyle(
            font: valueFont,
            fontSize: 12,
            color: const PdfColor.fromInt(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  /// Trigger native download / print / share dialog
  static Future<void> downloadOrPrintPdf(BuildContext context, Itinerary itinerary) async {
    try {
      final bytes = await generateItineraryPdf(itinerary);
      final filename = 'LocalLens_${itinerary.destination.replaceAll(' ', '_')}_Itinerary.pdf';

      await Printing.layoutPdf(
        name: filename,
        onLayout: (PdfPageFormat format) async => bytes,
      );
    } catch (e) {
      debugPrint('[ItineraryPdfService] Error generating/downloading PDF: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
