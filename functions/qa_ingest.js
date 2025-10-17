const functions = require("firebase-functions");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

function ensureAuthorized(context) {
  if (!context.auth || !context.auth.token || !context.auth.token.role) {
    throw new functions.https.HttpsError('unauthenticated', 'Kimlik doğrulama gerekli.');
  }
  const role = String(context.auth.token.role).toLowerCase();
  if (!['admin', 'superadmin'].includes(role)) {
    throw new functions.https.HttpsError('permission-denied', 'QA sonuçlarını yalnızca yönetici veya süper yönetici içe aktarabilir.');
  }
}

function resolveCompanyId(context, companyId) {
  const resolved = companyId || context.auth?.token?.company_id || context.auth?.token?.companyId;
  if (!resolved) {
    throw new functions.https.HttpsError('failed-precondition', 'company_id alanı zorunludur');
  }
  return resolved;
}

exports.ingestQaRun = functions.https.onCall(async (data, context) => {
  ensureAuthorized(context);
  const companyId = resolveCompanyId(context, data.company_id);

  const payload = {
    company_id: companyId,
    source: String(data.source || 'CI').toUpperCase(),
    status: String(data.status || 'success'),
    total: Number(data.total || 0),
    passed: Number(data.passed || 0),
    failed: Number(data.failed || 0),
    skipped: Number(data.skipped || 0),
    coveragePct: Number(data.coveragePct || 0),
    durationSec: Number(data.durationSec || 0),
    created_at: data.created_at ? new Date(data.created_at) : admin.firestore.FieldValue.serverTimestamp(),
    artifacts: data.artifacts || {},
    failures: data.failures || [],
  };

  try {
    await admin.firestore().collection('qa_runs').add(payload);
    return {success: true};
  } catch (error) {
    logger.error('QA içe aktarımı başarısız oldu', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});
