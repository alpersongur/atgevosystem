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


async function countDocuments(query) {
  try {
    const snapshot = await query.count().get();
    const data = snapshot.data();
    return data && typeof data.count === "number" ? data.count : 0;
  } catch (error) {
    logger.warn("Count aggregation failed, falling back to in-memory count", error);
    const snapshot = await query.get();
    return snapshot.size;
  }
}

async function calculateInventorySummary(db) {
  const snapshot = await db.collection("inventory").get();
  let totalValue = 0;
  let lowStock = 0;

  snapshot.forEach((doc) => {
    const data = doc.data() || {};
    const quantity = Number(data.quantity || 0);
    if (quantity <= 0) {
      if ((Number(data.min_stock || 0)) > 0) {
        lowStock += 1;
      }
      return;
    }

    const minStock = Number(data.min_stock || 0);
    if (minStock > 0 && quantity < minStock) {
      lowStock += 1;
    }

    const unitCandidates = [
      data.unit_cost,
      data.unit_price,
      data.avg_cost,
      data.average_cost,
    ];

    let unitCost = 0;
    for (const candidate of unitCandidates) {
      const parsed = Number(candidate);
      if (!Number.isNaN(parsed) && parsed > 0) {
        unitCost = parsed;
        break;
      }
    }

    if (unitCost > 0) {
      totalValue += unitCost * quantity;
    } else if (typeof data.total_value === "number") {
      totalValue += Number(data.total_value || 0);
    }
  });

  return {totalValue, lowStock};
}

async function calculateOutstandingInvoices(db) {
  const openStatuses = ["unpaid", "partial"];
  const invoicesSnapshot = await db.collection("invoices")
      .where("status", "in", openStatuses)
      .get();

  if (invoicesSnapshot.empty) {
    return 0;
  }

  const invoiceTotals = new Map();
  const invoiceIds = [];

  invoicesSnapshot.forEach((doc) => {
    const data = doc.data() || {};
    const grandTotal = Number(data.grand_total || data.grandTotal || 0);
    if (grandTotal <= 0) return;
    invoiceTotals.set(doc.id, grandTotal);
    invoiceIds.push(doc.id);
  });

  if (invoiceTotals.size === 0) {
    return 0;
  }

  const chunkSize = 10;
  const paymentsCollection = db.collection("payments");
  const paidTotals = new Map();

  for (let i = 0; i < invoiceIds.length; i += chunkSize) {
    const chunk = invoiceIds.slice(i, i + chunkSize);
    const paymentsSnapshot = await paymentsCollection
        .where("invoice_id", "in", chunk)
        .get();

    paymentsSnapshot.forEach((doc) => {
      const data = doc.data() || {};
      const invoiceId = data.invoice_id;
      const amount = Number(data.amount || 0);
      if (!invoiceId || Number.isNaN(amount)) return;
      paidTotals.set(invoiceId, (paidTotals.get(invoiceId) || 0) + amount);
    });
  }

  let outstanding = 0;
  invoiceTotals.forEach((grandTotal, invoiceId) => {
    const paid = paidTotals.get(invoiceId) || 0;
    const remaining = grandTotal - paid;
    if (remaining > 0) {
      outstanding += remaining;
    }
  });

  return outstanding;
}

async function summarizeMetricsTask() {
  const db = admin.firestore();
  const now = new Date();
  const dateKey = `${now.getFullYear()}${String(now.getMonth() + 1).padStart(2, "0")}${String(now.getDate()).padStart(2, "0")}`;

  const summary = {};

  summary.totalCustomers = await countDocuments(db.collection("customers"));
  summary.openQuotes = await countDocuments(
      db.collection("quotes").where("status", "in", ["pending", "in_production"]),
  );
  summary.activeProductionOrders = await countDocuments(
      db.collection("production_orders")
          .where("status", "in", ["waiting", "in_progress", "quality_check"]),
  );
  summary.pendingShipments = await countDocuments(
      db.collection("shipments")
          .where("status", "in", ["preparing", "on_the_way"]),
  );

  const outstanding = await calculateOutstandingInvoices(db);
  summary.outstandingInvoices = Number(outstanding.toFixed(2));

  const {totalValue, lowStock} = await calculateInventorySummary(db);
  summary.totalInventoryValue = Number(totalValue.toFixed(2));
  summary.lowStockCount = lowStock;

  await db.collection("dashboard_snapshots")
      .doc(dateKey)
      .set({
        summary,
        series: [],
        generated_at: admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});

  logger.info("Dashboard metrics summarized", {dateKey, summary});
}

async function getSystemMetricsCallable() {
  const metrics = await buildMetricsSnapshot();
  return metrics;
}

module.exports = {
  collectMetricsTask,
  getSystemMetricsCallable,
  summarizeMetricsTask,
};
