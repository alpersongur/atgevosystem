const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

async function fetchActiveLicense(companyRef) {
  const snapshot = await companyRef
      .collection("licenses")
      .where("status", "in", ["active", "pending"])
      .orderBy("end_date", "desc")
      .limit(1)
      .get();
  if (snapshot.empty) {
    return null;
  }
  const doc = snapshot.docs[0];
  return {id: doc.id, ref: doc.ref, data: doc.data()};
}

async function notifyCompany(companyId, companyData, licenseData) {
  const message = `Lisans süreniz ${licenseData.end_date.toDate().toISOString().split("T")[0]} tarihinde sona erdi. Sisteme erişim kısıtlandı.`;

  await db.collection("system_notifications").add({
    type: "warning",
    title: "Lisans Süresi Doldu",
    message,
    target: "/licenses",
    roles: ["admin"],
    company_id: companyId,
    created_at: FieldValue.serverTimestamp(),
  });

  const ownerEmail = companyData.owner_email || companyData.email;
  if (ownerEmail) {
    await db.collection("mail").add({
      to: ownerEmail,
      message: {
        subject: "ATG Makina ERP - Lisans Süresi Doldu",
        text: message,
      },
    }).catch((error) => logger.error("Lisans e-postası kuyruğa alınamadı", error));
  }

  try {
    await admin.messaging().sendToTopic(`company_${companyId}`, {
      notification: {
        title: "Lisans Süresi Doldu",
        body: message,
      },
      data: {
        type: "license_expired",
        companyId,
      },
    });
  } catch (error) {
    logger.error("Lisans bildirimi gönderilemedi", {companyId, error});
  }
}

async function processCompany(company) {
  const companyId = company.id;
  const data = company.data();
  const companyRef = company.ref;
  const activeLicense = await fetchActiveLicense(companyRef);
  if (!activeLicense) {
    return;
  }
  const endDate = activeLicense.data.end_date;
  if (!endDate || !endDate.toDate) {
    return;
  }
  const now = admin.firestore.Timestamp.now();
  if (endDate.toDate() >= now.toDate()) {
    return;
  }

  await activeLicense.ref.update({
    status: "expired",
    updated_at: FieldValue.serverTimestamp(),
  });

  await companyRef.update({
    status: "expired",
    updated_at: FieldValue.serverTimestamp(),
  });

  await notifyCompany(companyId, data, activeLicense.data);
  logger.info("Süresi dolan lisans işlendi", {companyId, licenseId: activeLicense.id});
}

async function licenseCheckTask() {
  const snapshot = await db.collection("companies").get();
  for (const company of snapshot.docs) {
    try {
      await processCompany(company);
    } catch (error) {
      logger.error("Lisans kontrolü başarısız", {companyId: company.id, error});
    }
  }
}

module.exports = {
  licenseCheckTask,
};
