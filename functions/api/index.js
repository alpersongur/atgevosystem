const express = require("express");
const cors = require("cors");
const rateLimit = require("express-rate-limit");
const admin = require("firebase-admin");
const functions = require("firebase-functions");
const swaggerUi = require("swagger-ui-express");
const crypto = require("crypto");

const createGraphQLServer = require("./graphql");
const openApiDocument = require("./openapi.json");

const app = express();

const allowedOrigins = (process.env.ALLOWED_ORIGINS || "*")
  .split(",")
  .map((origin) => origin.trim())
  .filter((origin) => origin.length > 0);

const corsOptions = {
  origin: (origin, callback) => {
    if (!origin || allowedOrigins.includes("*") || allowedOrigins.includes(origin)) {
      callback(null, true);
    } else {
      callback(new Error("Origin not allowed"));
    }
  },
  credentials: true,
};

app.use(cors(corsOptions));
app.use(express.json());
app.use(express.urlencoded({extended: true}));

const limiter = rateLimit({
  windowMs: 60 * 1000,
  max: 60,
  keyGenerator: (req) => req.headers["x-api-key"] || req.headers.authorization || req.ip,
});
app.use(limiter);

app.get("/v1/docs", swaggerUi.serve, swaggerUi.setup(openApiDocument));

async function validateCompanyActive(companyId) {
  const doc = await admin.firestore().collection("companies").doc(companyId).get();
  if (!doc.exists) {
    throw new Error("COMPANY_NOT_FOUND");
  }
  if ((doc.data().status ?? "active") !== "active") {
    throw new Error("COMPANY_INACTIVE");
  }
  return doc;
}

async function resolveApiKey(companyId, apiKey) {
  const hash = crypto.createHash("sha256").update(apiKey).digest("hex");
  const snapshot = await admin
      .firestore()
      .collection("companies")
      .doc(companyId)
      .collection("api_keys")
      .where("hashed_key", "==", hash)
      .limit(1)
      .get();
  if (snapshot.empty) {
    throw new Error("INVALID_API_KEY");
  }
  const keyDoc = snapshot.docs[0];
  const data = keyDoc.data();
  if (data.status === "revoked") {
    throw new Error("API_KEY_REVOKED");
  }
  return {
    id: keyDoc.id,
    scopes: data.scopes || [],
  };
}

function requireScope(scope) {
  return (req, res, next) => {
    if (req.authContext?.type === "apiKey") {
      const scopes = req.authContext.scopes || [];
      if (!scopes.includes(scope)) {
        return res.status(403).json({error: "INSUFFICIENT_SCOPE"});
      }
    }
    next();
  };
}

async function authMiddleware(req, res, next) {
  try {
    const authHeader = req.headers.authorization || "";
    const apiKey = req.headers["x-api-key"];
    let companyId = req.headers["x-company-id"] || null;
    const context = {
      type: null,
      companyId: null,
      userId: null,
      scopes: [],
    };

    if (authHeader.startsWith("Bearer ")) {
      const token = authHeader.replace("Bearer ", "").trim();
      const decoded = await admin.auth().verifyIdToken(token);
      context.type = "firebase";
      context.userId = decoded.uid;
      companyId = companyId || decoded.company_id || decoded.companyId || null;
    } else if (apiKey) {
      if (!companyId) {
        return res.status(400).json({error: "COMPANY_ID_REQUIRED"});
      }
      const apiKeyData = await resolveApiKey(companyId, apiKey);
      context.type = "apiKey";
      context.scopes = apiKeyData.scopes;
      context.userId = apiKeyData.id;
    } else {
      return res.status(401).json({error: "AUTH_REQUIRED"});
    }

    if (!companyId) {
      return res.status(400).json({error: "COMPANY_ID_REQUIRED"});
    }

    await validateCompanyActive(companyId);

    context.companyId = companyId;
    req.authContext = context;
    next();
  } catch (error) {
    const code = error.message || error.code || "AUTH_ERROR";
    functions.logger.error("API auth failed", error);
    res.status(401).json({error: code});
  }
}

app.use(authMiddleware);

app.get("/v1/crm/customers", requireScope("crm.read"), async (req, res) => {
  try {
    const companyId = req.authContext.companyId;
    const snapshot = await admin
        .firestore()
        .collection("companies")
        .doc(companyId)
        .collection("customers")
        .limit(100)
        .get();
    const result = snapshot.docs.map((doc) => ({id: doc.id, ...doc.data()}));
    res.json({data: result});
  } catch (error) {
    functions.logger.error("GET customers failed", error);
    res.status(500).json({error: "INTERNAL"});
  }
});

app.post("/v1/crm/customers", requireScope("crm.write"), async (req, res) => {
  try {
    const companyId = req.authContext.companyId;
    const payload = {
      name: req.body.name ?? "",
      email: req.body.email ?? null,
      phone: req.body.phone ?? null,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };
    const ref = await admin
        .firestore()
        .collection("companies")
        .doc(companyId)
        .collection("customers")
        .add(payload);
    res.status(201).json({id: ref.id, ...payload});
  } catch (error) {
    functions.logger.error("POST customer failed", error);
    res.status(500).json({error: "INTERNAL"});
  }
});

app.get("/v1/finance/invoices", requireScope("finance.read"), async (req, res) => {
  try {
    const companyId = req.authContext.companyId;
    let query = admin.firestore()
        .collection("companies")
        .doc(companyId)
        .collection("invoices");
    if (req.query.status) {
      query = query.where("status", "==", req.query.status);
    }
    const snapshot = await query.limit(100).get();
    const result = snapshot.docs.map((doc) => ({id: doc.id, ...doc.data()}));
    res.json({data: result});
  } catch (error) {
    functions.logger.error("GET invoices failed", error);
    res.status(500).json({error: "INTERNAL"});
  }
});

app.post("/v1/finance/payments", requireScope("finance.write"), async (req, res) => {
  try {
    const companyId = req.authContext.companyId;
    const payload = {
      invoice_id: req.body.invoice_id,
      amount: Number(req.body.amount || 0),
      method: req.body.method ?? "manual",
      created_at: new Date().toISOString(),
    };
    if (!payload.invoice_id || isNaN(payload.amount)) {
      return res.status(400).json({error: "INVALID_PAYLOAD"});
    }
    const ref = await admin
        .firestore()
        .collection("companies")
        .doc(companyId)
        .collection("payments")
        .add(payload);
    res.status(201).json({id: ref.id, ...payload});
  } catch (error) {
    functions.logger.error("POST payment failed", error);
    res.status(500).json({error: "INTERNAL"});
  }
});

app.get("/v1/inventory/items", requireScope("inventory.read"), async (req, res) => {
  try {
    const companyId = req.authContext.companyId;
    const snapshot = await admin
        .firestore()
        .collection("companies")
        .doc(companyId)
        .collection("inventory")
        .limit(200)
        .get();
    const result = snapshot.docs.map((doc) => ({id: doc.id, ...doc.data()}));
    res.json({data: result});
  } catch (error) {
    functions.logger.error("GET inventory failed", error);
    res.status(500).json({error: "INTERNAL"});
  }
});

app.post("/v1/inventory/adjust", requireScope("inventory.write"), async (req, res) => {
  try {
    const companyId = req.authContext.companyId;
    const itemId = req.body.item_id;
    const delta = Number(req.body.delta || 0);
    if (!itemId || isNaN(delta)) {
      return res.status(400).json({error: "INVALID_PAYLOAD"});
    }
    const itemRef = admin
        .firestore()
        .collection("companies")
        .doc(companyId)
        .collection("inventory")
        .doc(itemId);
    await admin.firestore().runTransaction(async (txn) => {
      const snap = await txn.get(itemRef);
      if (!snap.exists) {
        throw new Error("ITEM_NOT_FOUND");
      }
      const data = snap.data();
      const updated = {
        ...data,
        quantity: (data.quantity || 0) + delta,
        updated_at: new Date().toISOString(),
      };
      txn.set(itemRef, updated);
    });
    const updatedSnap = await itemRef.get();
    res.json({id: updatedSnap.id, ...updatedSnap.data()});
  } catch (error) {
    if (error.message === "ITEM_NOT_FOUND") {
      return res.status(404).json({error: "ITEM_NOT_FOUND"});
    }
    functions.logger.error("POST envanter ayarlaması başarısız oldu", error);
    res.status(500).json({error: "INTERNAL"});
  }
});

(async () => {
  try {
    const server = await createGraphQLServer();
    server.applyMiddleware({app, path: "/v1/graphql"});
  } catch (error) {
    functions.logger.error("GraphQL başlangıcı başarısız oldu", error);
  }
})();

module.exports = app;
