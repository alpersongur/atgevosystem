/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const functions = require("firebase-functions");
const {setGlobalOptions} = functions;
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

admin.initializeApp();

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
    // Placeholder implementation. Replace with real usage API calls.
    // Return mock usage stats until integration is implemented.
    return {
      projectId,
      users: 0,
      modules: [],
      read: 0,
      write: 0,
      delete: 0,
      updated_at: new Date().toISOString(),
    };
  } catch (error) {
    logger.error("Failed to fetch usage for project", projectId, error);
    return {};
  }
}

/**
 * Scheduled task that refreshes usage metrics for each company.
 * @param {functions.EventContext} context Cloud Functions context
 * @return {Promise<void>} Resolved when sync completes
 */
exports.collectUsageData = functions.pubsub
    .schedule("every 6 hours")
    .onRun(async (context) => {
      logger.info("Running scheduled usage collection");
      const companiesSnapshot = await admin.firestore()
          .collection("companies")
          .get();
      for (const company of companiesSnapshot.docs) {
        const data = company.data();
        const projectId = data.firebase_project_id ||
        data.projectId;
        if (!projectId) {
          logger.warn("Skipping company without project id", company.id);
          continue;
        }

        const usageData = await getFirebaseUsage(projectId);
        await company.ref.update({
          usage: usageData,
          last_sync: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    });

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
