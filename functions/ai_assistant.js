const admin = require("firebase-admin");
const functions = require("firebase-functions");
const logger = require("firebase-functions/logger");

const db = admin.firestore();

exports.aiQuery = functions.https.onCall(async (data, context) => {
  const question = data?.question;
  const companyId = data?.company_id;

  if (!context.auth || !context.auth.token || !context.auth.token.role) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Bu işlev sadece yetkili kullanıcılar tarafından kullanılabilir.',
    );
  }

  if (!question || typeof question !== 'string') {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Geçerli bir soru gerekli.',
    );
  }

  const normalized = question.toLowerCase();
  let intent = 'general';
  let answer = 'Soruyu işlemek için ek entegrasyon gerekli.';

  try {
    if (normalized.includes('müşteri')) {
      intent = 'crm';
      answer = await countCollection(companyId, 'customers', 'created_at');
    } else if (normalized.includes('satış') || normalized.includes('ciro')) {
      intent = 'finance';
      answer = await sumCollection(companyId, 'invoices', 'amount');
    }

    await db.collection('assistant_logs').add({
      company_id: companyId,
      user_id: context.auth.uid,
      question,
      answer,
      intent,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      answer,
      intent,
      suggestions: [],
    };
  } catch (error) {
    logger.error('AI assistant callable failed', error);
    throw new functions.https.HttpsError(
      'internal',
      'Soru işlenirken hata oluştu.',
    );
  }
});

async function countCollection(companyId, collection, dateField) {
  const query = await db
      .collection('companies')
      .doc(companyId)
      .collection(collection)
      .get();
  return `${query.size} kayıt bulundu.`;
}

async function sumCollection(companyId, collection, amountField) {
  const snapshot = await db
      .collection('companies')
      .doc(companyId)
      .collection(collection)
      .get();
  let total = 0;
  snapshot.forEach((doc) => {
    const data = doc.data();
    total += Number(data[amountField] || 0);
  });
  return `Toplam tutar ${total.toFixed(2)} ₺`;
}
