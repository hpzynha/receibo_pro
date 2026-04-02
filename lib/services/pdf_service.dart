import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/recibo.dart';

class PdfService {
  static final PdfService _instance = PdfService._internal();
  factory PdfService() => _instance;
  PdfService._internal();

  static const PdfColor _green = PdfColor.fromInt(0xFF0FA374);
  static const PdfColor _greenLight = PdfColor.fromInt(0xFF1DB88A);
  static const PdfColor _textDark = PdfColor.fromInt(0xFF0F1117);
  static const PdfColor _textMuted = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor _border = PdfColor.fromInt(0xFFE0DDD8);

  final _currencyFmt = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );

  Future<Uint8List> generatePdf(Recibo recibo) async {
    final doc = pw.Document();

    // Carregar fonte
    final fontRegular = await PdfGoogleFonts.dMSansRegular();
    final fontBold = await PdfGoogleFonts.dMSansBold();
    final fontSoraBold = await PdfGoogleFonts.soraBold();
    final fontSoraExtraBold = await PdfGoogleFonts.soraExtraBold();

    // TODO: PRO — carregar logoPath se isPro e recibo.logoPath != null
    // final logoImage = recibo.logoPath != null
    //     ? pw.MemoryImage(File(recibo.logoPath!).readAsBytesSync())
    //     : null;

    final dataFormatada = DateFormat('dd/MM/yyyy').format(recibo.data);
    final valorFormatado = _currencyFmt.format(recibo.valor);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  // TODO: PRO — substituir por logoImage se disponível
                  pw.RichText(
                    text: pw.TextSpan(
                      children: [
                        pw.TextSpan(
                          text: 'Recibo',
                          style: pw.TextStyle(
                            font: fontSoraExtraBold,
                            fontSize: 22,
                            color: _textDark,
                          ),
                        ),
                        pw.TextSpan(
                          text: 'Pro',
                          style: pw.TextStyle(
                            font: fontSoraExtraBold,
                            fontSize: 22,
                            color: _greenLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: const pw.BoxDecoration(
                      color: _green,
                      borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Text(
                      'RECIBO',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 10,
                        color: PdfColors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),

              pw.Divider(color: _border, height: 24),

              // ── Título + Número ──────────────────────────────────────────
              pw.Text(
                'Recibo de Pagamento',
                style: pw.TextStyle(
                  font: fontSoraBold,
                  fontSize: 18,
                  color: _textDark,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                children: [
                  pw.Text(
                    'Nº ${recibo.numeracao}',
                    style: pw.TextStyle(
                      font: fontRegular,
                      fontSize: 11,
                      color: _textMuted,
                    ),
                  ),
                  pw.Text(
                    '   ·   ',
                    style: pw.TextStyle(
                      font: fontRegular,
                      fontSize: 11,
                      color: _textMuted,
                    ),
                  ),
                  pw.Text(
                    dataFormatada,
                    style: pw.TextStyle(
                      font: fontRegular,
                      fontSize: 11,
                      color: _textMuted,
                    ),
                  ),
                ],
              ),

              pw.Divider(color: _border, height: 28),

              // ── Tabela de dados ──────────────────────────────────────────
              _buildRow(
                'Prestador',
                recibo.prestadorNome,
                fontRegular,
                fontBold,
              ),
              _buildRow('CPF / CNPJ', recibo.prestadorCpf, fontRegular, fontBold),
              _buildRow(
                'Cliente',
                recibo.clienteNome,
                fontRegular,
                fontBold,
              ),
              _buildRow('Serviço', recibo.servico, fontRegular, fontBold),
              _buildRow('Data', dataFormatada, fontRegular, fontBold),

              // TODO: PRO — campo observações
              if (recibo.observacoes != null && recibo.observacoes!.isNotEmpty)
                _buildRow(
                  'Observações',
                  recibo.observacoes!,
                  fontRegular,
                  fontBold,
                ),

              pw.Divider(color: _border, height: 28),

              // ── Total ────────────────────────────────────────────────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'TOTAL',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 13,
                      color: _textDark,
                      letterSpacing: 0.5,
                    ),
                  ),
                  pw.Text(
                    valorFormatado,
                    style: pw.TextStyle(
                      font: fontSoraExtraBold,
                      fontSize: 28,
                      color: _greenLight,
                    ),
                  ),
                ],
              ),

              pw.Spacer(),

              // ── Rodapé ───────────────────────────────────────────────────
              pw.Divider(color: _border, height: 16),
              pw.Center(
                child: pw.Text(
                  'Gerado com ReciboPro · Documento sem validade fiscal',
                  style: pw.TextStyle(
                    font: fontRegular,
                    fontSize: 8,
                    color: _textMuted,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  pw.Widget _buildRow(
    String label,
    String value,
    pw.Font fontRegular,
    pw.Font fontBold,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 110,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                font: fontRegular,
                fontSize: 11,
                color: _textMuted,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 11,
                color: _textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> sharePdf(Uint8List bytes, String numeracao) async {
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'recibo_$numeracao.pdf',
    );
  }

  Future<void> savePdfToDevice(Uint8List bytes, String numeracao) async {
    await Printing.layoutPdf(
      onLayout: (_) => bytes,
      name: 'recibo_$numeracao',
    );
  }
}
