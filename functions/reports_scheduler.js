const functions = require("firebase-functions");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

const {
  fetchReportData,
  toCsv,
  toXlsx,
  toPdf,
} = require("./report_utils");

function isDue(schedule, now) {
  const frequency = schedule.frequency || 'DAILY';
  const lastSent = schedule.last_sent_at ? schedule.last_sent_at.toDate() : null;
  const todayKey = now.toISOString().substring(0, 10);
  const lastKey = lastSent ? lastSent.toISOString().substring(0, 10) : null;
  if (lastKey === todayKey) {
    return false;
  }
  if (frequency === 'DAILY') {
    return true;
  }
  if (frequency === 'WEEKLY') {
    const day = schedule.dayOfWeek || 1;
    const currentDay = (now.getDay() === 0 ? 7 : now.getDay());
    return currentDay === day;
  }
  if (frequency === 'MONTHLY') {
    const day = schedule.dayOfMonth || 1;
    return now.getDate() === day;
  }
  return false;
}

async function createAttachment(reportType, format, reportData) {
  switch (format) {
    case 'pdf':
      return {
        filename: `${reportType}-${Date.now()}.pdf`,
        contentType: 'application/pdf',
        content: await toPdf(reportData, reportType),
      };
    case 'xlsx':
      return {
        filename: `${reportType}-${Date.now()}.xlsx`,
        contentType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        content: Buffer.from(await toXlsx(reportData)),
      };
    case 'csv':
    default:
      return {
        filename: `${reportType}-${Date.now()}.csv`,
        contentType: 'text/csv',
        content: toCsv(reportData),
      };
  }
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

exports.sendScheduledReport = functions.pubsub
    .schedule('0 6 * * *')
    .timeZone('Europe/Istanbul')
    .onRun(async () => {
      const now = new Date();
      const companies = await admin.firestore().collection('companies').get();
      for (const company of companies.docs) {
        const companyId = company.id;
        const schedulesSnapshot = await company.ref
            .collection('report_schedules')
            .where('active', '==', true)
            .get();
        for (const scheduleDoc of schedulesSnapshot.docs) {
          const schedule = scheduleDoc.data();
          try {
            if (!isDue(schedule, now)) {
              continue;
            }

            const filters = schedule.filters || {};
            const reportData = await fetchReportData({
              companyId,
              reportType: schedule.report_type,
              dateFrom: filters.dateFrom ? new Date(filters.dateFrom) : new Date(Date.now() - 30 * 24 * 60 * 60 * 1000),
              dateTo: filters.dateTo ? new Date(filters.dateTo) : now,
              filters,
            });

            const attachment = await createAttachment(schedule.report_type, schedule.format || 'pdf', reportData);
            await enqueueEmail({
              companyId,
              to: schedule.emails || [],
              subject: `ATG ERP Zamanlanmış Raporu - ${schedule.report_type}`,
              text: 'Zamanlanmış raporunuz ektedir.',
              attachment,
            });

            await scheduleDoc.ref.update({
              last_sent_at: admin.firestore.FieldValue.serverTimestamp(),
            });

            await company.ref.collection('report_logs').add({
              scheduleId: scheduleDoc.id,
              status: 'sent',
              ts: admin.firestore.FieldValue.serverTimestamp(),
              details: `${schedule.emails?.join(', ') ?? ''} adresine gönderildi`,
            });
          } catch (error) {
            logger.error('Zamanlanmış rapor oluşturma başarısız oldu', error);
            await company.ref.collection('report_logs').add({
              scheduleId: scheduleDoc.id,
              status: 'error',
              ts: admin.firestore.FieldValue.serverTimestamp(),
              details: error.message,
            });
          }
        }
      }
    });
