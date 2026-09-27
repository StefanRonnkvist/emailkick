part of 'email_composer_page.dart';

enum _ProfileField {
  fromName,
  fromEmail,
  replyTo,
  phone,
  company,
  department,
  to,
  cc,
  bcc,
  customerName,
  customerEmail,
  customerPhone,
  customerAddress,
}

/// Email intents used to derive subject text and describe the draft body.
enum _ContentMode {
  expedite,
  rush,
  machineDown,
  partLookup,
  quotePart,
  shipImmediately,
}
