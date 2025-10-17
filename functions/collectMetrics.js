const admin = require("firebase-admin");
const {logger} = require("firebase-functions/logger");

async function buildMetricsSnapshot() {
  const db = admin.firestore();
  const now = new Date();
  const twentyFourHoursAgo = new Date(now.getTime() - 24 * 60 * 60 * 1000);

  const logSnapshot = await db
      .collection("system_logs")
      .where("timestamp", ">=", twentyFourHoursAgo)
      .get();

  let reads = 0;
  let writes = 0;
  let deletes = 0;
  let errors = 0;

  const updateCounters = (data) => {
    const type = ((data.type || "") + "").toLowerCase();
    if (type === "error") {
      errors += 1;
    }
    const action = ((data.action || data.event || "") + "").toLowerCase();
    if (action.indexOf("read") !== -1) reads += 1;
    if (action.indexOf("write") !== -1) writes += 1;
    if (action.indexOf("delete") !== -1) deletes += 1;
  };

  logSnapshot.forEach((doc) => {
    updateCounters(doc.data());
  });

  let storageMb = 0;
  try {
    const [metadata] = await admin.storage().bucket().getMetadata();
    const totalSize = metadata && metadata.size ? Number(metadata.size) : 0;
    storageMb = totalSize / (1024 * 1024);
  } catch (error) {
    logger.warn("Failed to fetch storage metadata", error);
  }

  let activeUsers = 0;
  try {
    const list = await admin.auth().listUsers(1000);
    activeUsers = list.users.length;
  } catch (error) {
    logger.warn("Failed to list users", error);
  }

  const hostingStatusDoc = await db
      .collection("system_settings")
      .doc("hosting_status")
      .get();
  let hostingStatus = "Bilinmiyor";
  if (hostingStatusDoc.exists) {
    const hostingData = hostingStatusDoc.data() || {};
    hostingStatus = hostingData.status || "Bilinmiyor";
  }

  return {
    reads,
    writes,
    deletes,
    storage_mb: Number(storageMb.toFixed(2)),
    errors,
    active_users: activeUsers,
    hosting_status: hostingStatus,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  };
}

async function collectMetricsTask() {
  const metrics = await buildMetricsSnapshot();
  const db = admin.firestore();
  const now = new Date();
  const dateKey = `${now.getFullYear()}` +
      `${String(now.getMonth() + 1).padStart(2, "0")}` +
      `${String(now.getDate()).padStart(2, "0")}`;

  const docRef = db
      .collection("system_metrics")
      .doc("daily")
      .collection("records")
      .doc(dateKey);

  await docRef.set(metrics, {merge: true});
  logger.info("System metrics snapshot stored", {dateKey});
}

async function getSystemMetricsCallable() {
  const metrics = await buildMetricsSnapshot();
  return metrics;
}

module.exports = {
  collectMetricsTask,
  getSystemMetricsCallable,
};
