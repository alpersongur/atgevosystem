const path = require('path');
const admin = require(
  require.resolve('firebase-admin', {
    paths: [path.join(__dirname, '..', 'functions')],
  }),
);

admin.initializeApp({
  credential: admin.credential.cert(
    require(path.join(__dirname, '..', '.secrets', 'serviceAccountKey.json')),
  ),
});

async function run() {
  const email = 'alpersongur97@gmail.com';
  const user = await admin.auth().getUserByEmail(email);
  const claims = {
    role: 'superadmin',
    modules: [
      'crm',
      'production',
      'finance',
      'purchasing',
      'inventory',
      'shipment',
      'admin',
      'dashboard',
    ],
  };
  await admin.auth().setCustomUserClaims(user.uid, claims);
  console.log('[CLAIMS] set for', email, 'uid:', user.uid, claims);
}

run()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
