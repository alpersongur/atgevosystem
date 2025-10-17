const {BigQuery} = require("@google-cloud/bigquery");
const functions = require("firebase-functions");
const logger = require("firebase-functions/logger");

const bigquery = new BigQuery();

exports.runBQQuery = functions.https.onCall(async (data, context) => {
  if (!context.auth || !context.auth.token || !context.auth.token.role) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Bu işlev yalnızca yetkili kullanıcılar tarafından kullanılabilir.",
    );
  }

  const role = String(context.auth.token.role).toLowerCase();
  if (!['admin', 'superadmin'].includes(role)) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Sadece admin ve superadmin roller sorgu çalıştırabilir.",
    );
  }

  const sql = data?.sql;
  const params = data?.params || {};
  const companyId = data?.company_id || context.auth.token.company_id;

  if (!sql || typeof sql !== "string") {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Geçerli bir SQL sorgusu gönderilmelidir.",
    );
  }

  if (!companyId) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "company_id bilgisi olmadan sorgu çalıştırılamaz.",
    );
  }

  const safeParams = {...params, company_id: companyId};

  // Wrap incoming SQL to enforce tenant filter.
  const wrappedSql = `SELECT * FROM (${sql}) WHERE company_id = @company_id`;

  const queryOptions = {
    query: wrappedSql,
    params: safeParams,
    useLegacySql: false,
  };

  try {
    const [job] = await bigquery.createQueryJob(queryOptions);
    const [rows] = await job.getQueryResults();

    return {
      rows,
      totalRows: rows.length,
      jobId: job.id,
    };
  } catch (error) {
    logger.error("BigQuery sorgusu başarısız", error);
    throw new functions.https.HttpsError(
      "internal",
      `BigQuery sorgusu çalıştırılamadı: ${error.message}`,
    );
  }
});
