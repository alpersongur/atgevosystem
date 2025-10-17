import 'dart:typed_data';

import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  EmailService._();

  static final EmailService instance = EmailService._();

  Future<void> sendQuoteEmail({
    required String recipientEmail,
    required String subject,
    required String body,
    required Uint8List pdfAttachment,
  }) async {
    final smtpServer = SmtpServer(
      'smtp.gmail.com',
      port: 587,
      username: 'youremail@gmail.com',
      password: 'app_password',
    );

    final message = Message()
      ..from = Address('youremail@gmail.com', 'ATG Makina ERP')
      ..recipients.add(recipientEmail)
      ..subject = subject
      ..text = body
      ..attachments = [
        StreamAttachment(
          Stream.fromIterable([pdfAttachment]),
          'application/pdf',
          fileName: 'Teklif.pdf',
        ),
      ];

    await send(message, smtpServer);
  }
}
