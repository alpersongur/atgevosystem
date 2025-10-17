const functions = require("firebase-functions");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

const {
  fetchReportData,
  toCsv,
  toXlsx,
  toPdf,
} = require("./report_utils");

function ensureAuthorized(context) {
  if (!context.auth || !context.auth.token || !context.auth.token.role) {
    throw new functions.https.HttpsError('unauthenticated', 'Kimlik doğrulama gerekli.');
  }
  const role = String(context.auth.token.role).toLowerCase();
  if (!['admin', 'superadmin'].includes(role)) {
    throw new functions.https.HttpsError('permission-denied', 'Rapor talebini yalnızca yönetici veya süper yönetici yapabilir.');
  }
}

function resolveCompanyId(context, companyId) {
  const resolved = companyId || context.auth?.token?.company_id || context.auth?.token?.companyId;
  if (!resolved) {
    throw new functions.https.HttpsError('failed-precondition', 'company_id alanı zorunludur');
  }
  return resolved;
}

async function enqueueEmail({companyId, to, subject, text, attachment}) {
  if (!to || to.length === 0) return;
  await admin.firestore().collection('mail').add({
    to,
    message: {
      subject,
      text,
      attachments: [
        {
          filename: attachment.filename,
          content: attachment.content.toString('base64'),
          encoding: 'base64',
          contentType: attachment.contentType,
        },
      ],
    },
    company_id: companyId,
  });
}

function buildFilename(reportType, format) {
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const normalized = (format || 'pdf').toLowerCase();
  return `${reportType}-${timestamp}.${normalized}`;
}

function formatAttachment(reportType, format, data) {
  const filename = buildFilename(reportType, format);
  switch (format) {
    case 'pdf':
      return toPdf(data, reportType).then((buffer) => ({
        filename,
        content: buffer,
        contentType: 'application/pdf',
      }));
    case 'xlsx':
      return toXlsx(data).then((buffer) => ({
        filename,
        content: Buffer.from(buffer),
        contentType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      }));
    case 'csv':
    default:
      return Promise.resolve({
        filename,
        content: toCsv(data),
        contentType: 'text/csv',
      });
  }
}

exports.requestImmediateReport = functions.https.onCall(async (data, context) => {
  ensureAuthorized(context);
  const {report_type: reportType, format = 'pdf', emails = [], filters = {}} = data || {};
  if (!reportType) {
    throw new functions.https.HttpsError('invalid-argument', 'report_type alanı zorunludur');
  }
  const companyId = resolveCompanyId(context, data.company_id);

  const dateFrom = filters.dateFrom ? new Date(filters.dateFrom) : new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
  const dateTo = filters.dateTo ? new Date(filters.dateTo) : new Date();

  try {
    const reportData = await fetchReportData({
      companyId,
      reportType,
      dateFrom,
      dateTo,
      filters,
    });

    const attachment = await formatAttachment(reportType, format, reportData);

    if (emails.length > 0) {
      await enqueueEmail({
        companyId,
        to: emails,
        subject: `ATG ERP Raporu - ${reportType}`,
        text: 'Raporunuz ektedir.',
        attachment,
      });
    }

    return {
      columns: reportData.columns,
      rows: reportData.rows,
      attachment: {
        filename: attachment.filename,
        contentType: attachment.contentType,
        contentBase64: attachment.content.toString('base64'),
      },
    };
  } catch (error) {
    logger.error('Anlık rapor oluşturma başarısız oldu', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});
