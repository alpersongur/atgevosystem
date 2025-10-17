const {ApolloServer, gql} = require("apollo-server-express");
const admin = require("firebase-admin");

const typeDefs = gql`
  type Customer {
    id: ID!
    name: String
    email: String
    phone: String
    created_at: String
  }

  type Invoice {
    id: ID!
    customer_id: String
    amount: Float
    status: String
    created_at: String
    due_date: String
  }

  type Payment {
    id: ID!
    invoice_id: String
    amount: Float
    method: String
    created_at: String
  }

  type Item {
    id: ID!
    name: String
    sku: String
    quantity: Float
    valuation: Float
    updated_at: String
  }

  type Query {
    customers(company_id: String!): [Customer!]!
    invoices(company_id: String!, status: String, startDate: String, endDate: String): [Invoice!]!
    inventory(company_id: String!): [Item!]!
  }

  type Mutation {
    addCustomer(company_id: String!, name: String!, email: String, phone: String): Customer!
    addPayment(company_id: String!, invoice_id: String!, amount: Float!, method: String): Payment!
    adjustInventory(company_id: String!, item_id: String!, delta: Float!): Item!
  }
`;

function requireScope(context, scope) {
  if (context?.auth?.type === "apiKey") {
    const scopes = context.auth.scopes || [];
    if (!scopes.includes(scope)) {
      throw new Error("INSUFFICIENT_SCOPE");
    }
  }
}

function collectionRef(companyId, path) {
  return admin.firestore().collection("companies").doc(companyId).collection(path);
}

const resolvers = {
  Query: {
    customers: async (_, args, context) => {
      const companyId = args.company_id;
      if (companyId !== context?.auth?.companyId) {
        throw new Error("TENANT_MISMATCH");
      }
      requireScope(context, "crm.read");
      const snapshot = await collectionRef(companyId, "customers").limit(200).get();
      return snapshot.docs.map((doc) => ({id: doc.id, ...doc.data()}));
    },
    invoices: async (_, args, context) => {
      const companyId = args.company_id;
      if (companyId !== context?.auth?.companyId) {
        throw new Error("TENANT_MISMATCH");
      }
      requireScope(context, "finance.read");
      let query = collectionRef(companyId, "invoices");
      if (args.status) {
        query = query.where("status", "==", args.status);
      }
      if (args.startDate) {
        query = query.where("created_at", ">=", args.startDate);
      }
      if (args.endDate) {
        query = query.where("created_at", "<=", args.endDate);
      }
      const snapshot = await query.limit(200).get();
      return snapshot.docs.map((doc) => ({id: doc.id, ...doc.data()}));
    },
    inventory: async (_, args, context) => {
      const companyId = args.company_id;
      if (companyId !== context?.auth?.companyId) {
        throw new Error("TENANT_MISMATCH");
      }
      requireScope(context, "inventory.read");
      const snapshot = await collectionRef(companyId, "inventory").limit(200).get();
      return snapshot.docs.map((doc) => ({id: doc.id, ...doc.data()}));
    },
  },
  Mutation: {
    addCustomer: async (_, args, context) => {
      const companyId = args.company_id;
      if (companyId !== context?.auth?.companyId) {
        throw new Error("TENANT_MISMATCH");
      }
      requireScope(context, "crm.write");
      const payload = {
        name: args.name,
        email: args.email ?? null,
        phone: args.phone ?? null,
        created_at: new Date().toISOString(),
      };
      const ref = await collectionRef(companyId, "customers").add(payload);
      return {id: ref.id, ...payload};
    },
    addPayment: async (_, args, context) => {
      const companyId = args.company_id;
      if (companyId !== context?.auth?.companyId) {
        throw new Error("TENANT_MISMATCH");
      }
      requireScope(context, "finance.write");
      const payload = {
        invoice_id: args.invoice_id,
        amount: args.amount,
        method: args.method ?? "manual",
        created_at: new Date().toISOString(),
      };
      const ref = await collectionRef(companyId, "payments").add(payload);
      return {id: ref.id, ...payload};
    },
    adjustInventory: async (_, args, context) => {
      const companyId = args.company_id;
      if (companyId !== context?.auth?.companyId) {
        throw new Error("TENANT_MISMATCH");
      }
      requireScope(context, "inventory.write");
      const itemRef = collectionRef(companyId, "inventory").doc(args.item_id);
      await admin.firestore().runTransaction(async (txn) => {
        const snap = await txn.get(itemRef);
        if (!snap.exists) {
          throw new Error("ITEM_NOT_FOUND");
        }
        const current = snap.data();
        const updated = {
          ...current,
          quantity: (current.quantity || 0) + args.delta,
          updated_at: new Date().toISOString(),
        };
        txn.set(itemRef, updated);
      });
      const updatedSnap = await itemRef.get();
      return {id: updatedSnap.id, ...updatedSnap.data()};
    },
  },
};

async function createGraphQLServer() {
  const server = new ApolloServer({
    typeDefs,
    resolvers,
    context: ({req}) => ({auth: req.authContext}),
  });
  await server.start();
  return server;
}

module.exports = createGraphQLServer;
