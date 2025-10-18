/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const functions = require("firebase-functions");
const functionsV1 = require("firebase-functions/v1");
const {setGlobalOptions} = functions;
const {onSchedule} = require("firebase-functions/v2/scheduler");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

admin.initializeApp();

const monitoring = require("./collectMetrics");
const licenseChecks = require("./license_check");
const aiAssistant = require("./ai_assistant");
const bqQuery = require("./bq_query");
const mzRefresh = require("./mz_refresh");
const apiApp = require("./api");
const reportCallable = require("./report_callable");
const reportsScheduler = require("./reports_scheduler");
const qaIngest = require("./qa_ingest");
const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
setGlobalOptions({maxInstances: 10});

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

/**
 * Fetches usage metrics for a Firebase project.
 * @param {string} projectId Firebase project identifier
 * @return {Promise<Object>} Usage payload
 */
async function getFirebaseUsage(projectId) {
  try {
    return {
      projectId,
      status: 'beta',
      message: 'Firebase Usage API entegrasyonu hazırlanıyor.',
      updated_at: new Date().toISOString(),
    };
  } catch (error) {
    logger.error("Proje için kullanım verileri alınamadı", projectId, error);
    return {
      projectId,
      status: 'error',
      message: 'Kullanım metrikleri alınamadı.',
      updated_at: new Date().toISOString(),
    };
  }
}

/**
 * Scheduled task that refreshes usage metrics for each company.
 * @param {functions.EventContext} context Cloud Functions context
 * @return {Promise<void>} Resolved when sync completes
 */
exports.collectUsageData = onSchedule("every 6 hours", async () => {
      logger.info("Zamanlanmış kullanım verisi toplama çalıştırılıyor");
      const companiesSnapshot = await db.collection("companies").get();
      for (const company of companiesSnapshot.docs) {
        const data = company.data();
        const projectId = data.firebase_project_id || data.projectId;
        if (!projectId) {
          logger.warn("Proje kimliği olmayan şirket atlandı", company.id);
          continue;
        }

        const usageData = await getFirebaseUsage(projectId);
        await company.ref.update({
          usage: usageData,
          last_sync: FieldValue.serverTimestamp(),
        });
      }
    });

exports.collectMetrics = onSchedule("every 6 hours", async () => monitoring.collectMetricsTask());
exports.summarizeMetrics = onSchedule({schedule: "0 3 * * *", timeZone: "Europe/Istanbul"}, async () => monitoring.summarizeMetricsTask());
exports.license_check = onSchedule({schedule: "0 2 * * *", timeZone: "Europe/Istanbul"}, async () => licenseChecks.licenseCheckTask());
exports.getSystemMetrics = functions.https.onCall(async () => monitoring.getSystemMetricsCallable());
exports.createUserWithRole = require("./createUserWithRole").createUserWithRole;
exports.aiQuery = aiAssistant.aiQuery;
exports.runBQQuery = bqQuery.runBQQuery;
exports.mz_refresh = mzRefresh.mz_refresh;
exports.api = functions.region("europe-west1").https.onRequest(apiApp);
exports.requestImmediateReport = reportCallable.requestImmediateReport;
exports.sendScheduledReport = reportsScheduler.sendScheduledReport;
exports.ingestQaRun = qaIngest.ingestQaRun;

/**
 * Creates a system notification document and logs the operation.
 * @param {Object} payload Notification payload
 * @param {string} payload.type Notification type
 * @param {string} payload.title Title
 * @param {string} payload.message Body
 * @param {string} [payload.target] Target route
 * @param {Array<string>} [payload.roles] Target roles/topics
 * @return {Promise<FirebaseFirestore.DocumentReference>}
 */
async function createSystemNotification(payload) {
  const notification = {
    type: payload.type || "info",
    title: payload.title || "Sistem Bildirimi",
    message: payload.message || "",
    target: payload.target || "",
    read: false,
    roles: payload.roles || [],
    created_at: FieldValue.serverTimestamp(),
  };

  const docRef = await db.collection("system_notifications").add(notification);
  logger.info("Sistem bildirimi oluşturuldu", {id: docRef.id, ...payload});
  return docRef;
}

/**
 * Sends an optional email by enqueuing it into the `mail` collection.
 * Designed to work with the Firebase Email extension.
 * @param {string} to Recipient email
 * @param {string} subject Subject
 * @param {string} text Message text
 * @return {Promise<void>}
 */
async function enqueueEmail(to, subject, text) {
  if (!to) return;
  try {
    await db.collection("mail").add({
      to,
      message: {subject, text},
    });
    logger.info("Bildirim e-postası kuyruğa alındı", {to, subject});
  } catch (error) {
    logger.error("E-posta kuyruğa alınamadı", error);
  }
}

/**
 * Sends FCM push notifications for a system notification.
 * @param {FirebaseFirestore.DocumentSnapshot} snap Firestore snapshot
 * @return {Promise<void>}
 */
async function sendPushNotification(snap) {
  const data = snap.data();
  if (!data) return;
  const roles = Array.isArray(data.roles) ? data.roles : [];
  if (roles.length === 0) return;

  const notifications = roles.map((role) => {
    const topic = `role_${role.toLowerCase()}`;
    const message = {
      topic,
      notification: {
        title: data.title || "Yeni Bildirim",
        body: data.message || "",
      },
      data: {
        target: data.target || "",
        notificationId: snap.id,
        type: data.type || "info",
      },
    };
    const logContext = {topic, notificationId: snap.id};
    return admin.messaging().send(message)
        .then(() => logger.info("FCM bildirimi gönderildi", logContext))
        .catch((error) => {
          const errorContext = {topic, error};
          logger.error("FCM bildirimi gönderilemedi", errorContext);
        });
  });

  await Promise.all(notifications);
}

/**
 * Ensures a production order exists for an approved quote.
 */
exports.onQuoteApproved = functionsV1.firestore
    .document("quotes/{quoteId}")
    .onUpdate(async (change, context) => {
      const before = change.before.data();
      const after = change.after.data();
      if (!after) return;

      let prevStatus = "";
      if (before && before.status) {
        prevStatus = String(before.status).toLowerCase();
      }
      let nextStatus = "";
      if (after.status) {
        nextStatus = String(after.status).toLowerCase();
      }

      if (prevStatus === "approved" || nextStatus !== "approved") {
        return;
      }

      const quoteId = context.params.quoteId;
      const customerId = after.customer_id || after.customerId || null;

      const existing = await db.collection("production_orders")
          .where("quote_id", "==", quoteId)
          .limit(1)
          .get();
      if (!existing.empty) {
        logger.info("Production order already exists for quote", {quoteId});
        return;
      }

      const productionData = {
        quote_id: quoteId,
        customer_id: customerId,
        status: "waiting",
        created_at: FieldValue.serverTimestamp(),
        updated_at: FieldValue.serverTimestamp(),
        auto_generated: true,
      };

      const productionRef = await db.collection("production_orders")
          .add(productionData);

      await createSystemNotification({
        type: "task",
        title: "Yeni Üretim Emri",
        message: `Onaylanan teklif için üretim emri oluşturuldu (#${quoteId}).`,
        target: `/production/detail/${productionRef.id}`,
        roles: ["production", "admin"],
      });
    });

/**
 * Creates a purchase request when inventory drops below minimum.
 */
exports.onInventoryBelowMin = functionsV1.firestore
    .document("inventory/{itemId}")
    .onWrite(async (change, context) => {
      const after = change.after.exists ? change.after.data() : null;
      const before = change.before.exists ? change.before.data() : null;
      if (!after) return;

      const quantity = Number(after.quantity || 0);
      const minStock = Number(after.min_stock || after.minStock || 0);
      if (quantity >= minStock || minStock <= 0) {
        return;
      }

      const previouslyLow =
          before &&
          Number(before.quantity || 0) < Number(before.min_stock || 0);
      if (previouslyLow) {
        // Already handled for this state.
        return;
      }

      const itemId = context.params.itemId;
      const requestedQty = Math.max(minStock - quantity, 0);

      const existing = await db.collection("purchase_requests")
          .where("inventory_item_id", "==", itemId)
          .where("status", "==", "pending")
          .limit(1)
          .get();
      if (existing.empty) {
        await db.collection("purchase_requests").add({
          inventory_item_id: itemId,
          requested_qty: requestedQty,
          status: "pending",
          auto_generated: true,
          created_at: FieldValue.serverTimestamp(),
          updated_at: FieldValue.serverTimestamp(),
        });
      }

      const stockProduct = after.product_name || after.productName || itemId;
      const stockMessage = `${stockProduct} stokta ${quantity} adet kaldı.`;
      await createSystemNotification({
        type: "alert",
        title: "Stok Alt Limite Düştü",
        message: stockMessage,
        target: `/inventory/detail/${itemId}`,
        roles: ["admin"],
      });
    });

/**
 * Generates notifications for overdue invoices.
 */
exports.onInvoiceOverdue = functionsV1.firestore
    .document("invoices/{invoiceId}")
    .onWrite(async (change, context) => {
      const after = change.after.exists ? change.after.data() : null;
      const before = change.before.exists ? change.before.data() : null;
      if (!after) return;

      const status = after.status ? String(after.status).toLowerCase() : "";
      if (!["unpaid", "partial"].includes(status)) {
        return;
      }

      const dueDateRaw = after.due_date || after.dueDate;
      const dueDate = toDate(dueDateRaw);
      if (!dueDate) return;

      const today = new Date();
      if (dueDate >= today) {
        return;
      }

      let wasOverdue = false;
      if (before) {
        const previousDueRaw = before.due_date || before.dueDate;
        const previousDue = toDate(previousDueRaw);
        if (previousDue && previousDue < today) {
          let prevStatusText = "";
          if (before.status) {
            prevStatusText = String(before.status).toLowerCase();
          }
          wasOverdue = ["unpaid", "partial"].includes(prevStatusText);
        }
      }
      if (wasOverdue) {
        return;
      }

      const invoiceId = context.params.invoiceId;
      const invoiceNo = after.invoice_no || after.invoiceNo || invoiceId;
      const customerId = after.customer_id || after.customerId || null;

      const overdueMessage = `#${invoiceNo} numaralı fatura vadesini geçti.`;
      await createSystemNotification({
        type: "alert",
        title: "Vadesi Geçmiş Fatura",
        message: overdueMessage,
        target: `/finance/invoices/${invoiceId}`,
        roles: ["admin"],
      });

      if (customerId) {
        try {
          const customerSnap = await db.collection("customers")
              .doc(customerId)
              .get();
          const customerData = customerSnap.data() || {};
          const customerEmail = customerData.email;
          if (customerEmail) {
            const readableDate = dueDate.toLocaleDateString("tr-TR");
            const reminderBase = `${invoiceNo} numaralı faturanızın ` +
                `vade tarihi ${readableDate}`;
            const reminderText = "Sayın müşterimiz, " +
                `${reminderBase} itibarıyla geçmiştir.`;
            await enqueueEmail(
                customerEmail,
                "Vadesi Geçmiş Fatura Hatırlatması",
                reminderText,
            );
          }
        } catch (error) {
          logger.error("Fatura e-postası için müşteri bilgileri alınamadı", error);
        }
      }
    });

/**
 * Creates shipment draft when production order is completed.
 */
exports.onProductionCompleted = functionsV1.firestore
    .document("production_orders/{orderId}")
    .onUpdate(async (change, context) => {
      const before = change.before.data();
      const after = change.after.data();
      if (!after) return;

      let prevStatus = "";
      if (before && before.status) {
        prevStatus = String(before.status).toLowerCase();
      }
      let nextStatus = "";
      if (after.status) {
        nextStatus = String(after.status).toLowerCase();
      }

      if (prevStatus === "completed" || nextStatus !== "completed") {
        return;
      }

      const orderId = context.params.orderId;
      const customerId = after.customer_id || after.customerId || null;

      const shipments = await db.collection("shipments")
          .where("production_order_id", "==", orderId)
          .limit(1)
          .get();

      if (shipments.empty) {
        await db.collection("shipments").add({
          production_order_id: orderId,
          customer_id: customerId,
          status: "preparing",
          created_at: FieldValue.serverTimestamp(),
          updated_at: FieldValue.serverTimestamp(),
          auto_generated: true,
        });
      }

      const completionMessage = `${orderId} numaralı üretim tamamlandı, ` +
          "sevkiyat taslağı oluşturuldu.";
      await createSystemNotification({
        type: "task",
        title: "Sevkiyat Taslağı Hazırlandı",
        message: completionMessage,
        target: `/shipment/list`,
        roles: ["sales", "admin"],
      });
    });

/**
 * Sends push notifications when a new system notification arrives.
 */
exports.onSystemNotificationCreated = functionsV1.firestore
    .document("system_notifications/{notificationId}")
    .onCreate(async (snap) => sendPushNotification(snap));

/**
 * Helper to parse various date formats to Date.
 * @param {any} value Source value
 * @return {Date|null}
 */
function toDate(value) {
  if (!value) return null;
  if (value instanceof admin.firestore.Timestamp) {
    return value.toDate();
  }
  if (value instanceof Date) return value;
  const parsed = new Date(value);
  return isNaN(parsed.getTime()) ? null : parsed;
}

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
