const functions = require('firebase-functions');
const admin = require('firebase-admin');

if (admin.apps.length === 0) {
  admin.initializeApp();
}

exports.createUserWithRole = functions.https.onCall(async (data, context) => {
  if (!context.auth || context.auth.token.role !== 'superadmin') {
    throw new functions.https.HttpsError(
        'permission-denied',
        'Only superadmin can create users.',
    );
  }

  const {
    email,
    password,
    displayName,
    role,
    modules = [],
  } = data || {};

  if (!email || !password || !displayName || !role) {
    throw new functions.https.HttpsError(
        'invalid-argument',
        'email, password, displayName ve role zorunludur.',
    );
  }

  const normalizedModules = Array.isArray(modules)
    ? modules.filter((module) => typeof module === 'string')
    : [];

  const userRecord = await admin.auth().createUser({email, password, displayName});
  await admin.auth().setCustomUserClaims(userRecord.uid, {
    role,
    modules: normalizedModules,
  });
  await admin.firestore().collection('users').doc(userRecord.uid).set({
    uid: userRecord.uid,
    email,
    display_name: displayName,
    role,
    modules: normalizedModules,
    is_active: true,
    created_at: admin.firestore.FieldValue.serverTimestamp(),
  });

  return {uid: userRecord.uid, role, email};
});
