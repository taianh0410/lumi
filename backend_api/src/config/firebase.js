import { existsSync, readFileSync } from 'node:fs';

import admin from 'firebase-admin';

let firebaseApp = null;

function configureFirebaseEmulatorHosts() {
  const firebaseEmulatorHost = process.env.FIREBASE_EMULATOR_HOST;

  if (!firebaseEmulatorHost) {
    return false;
  }

  process.env.FIRESTORE_EMULATOR_HOST = process.env.FIRESTORE_EMULATOR_HOST || firebaseEmulatorHost;
  process.env.FIREBASE_AUTH_EMULATOR_HOST =
    process.env.FIREBASE_AUTH_EMULATOR_HOST || 'localhost:9099';
  process.env.FIREBASE_STORAGE_EMULATOR_HOST =
    process.env.FIREBASE_STORAGE_EMULATOR_HOST || 'localhost:9199';

  return true;
}

function hasCredentials() {
  return Boolean(
    process.env.FIREBASE_SERVICE_ACCOUNT_PATH ||
      process.env.GOOGLE_APPLICATION_CREDENTIALS ||
      (process.env.FIREBASE_PROJECT_ID &&
        process.env.FIREBASE_CLIENT_EMAIL &&
        process.env.FIREBASE_PRIVATE_KEY),
  );
}

function createPrivateKey(value) {
  if (!value) {
    return undefined;
  }

  return value.replace(/\\n/g, '\n');
}

function createCredentialFromServiceAccountPath(serviceAccountPath) {
  if (!existsSync(serviceAccountPath)) {
    throw new Error(`Firebase service account file not found: ${serviceAccountPath}`);
  }

  const serviceAccount = JSON.parse(readFileSync(serviceAccountPath, 'utf8'));

  return admin.credential.cert({
    projectId: serviceAccount.project_id,
    clientEmail: serviceAccount.client_email,
    privateKey: createPrivateKey(serviceAccount.private_key),
  });
}

function initializeFirebase() {
  if (firebaseApp) {
    return firebaseApp;
  }

  try {
    const emulatorMode = configureFirebaseEmulatorHosts();

    if (admin.apps.length > 0) {
      firebaseApp = admin.app();
      return firebaseApp;
    }

    if (!hasCredentials() && !emulatorMode) {
      return null;
    }

    const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH || process.env.GOOGLE_APPLICATION_CREDENTIALS;
    const projectId = process.env.FIREBASE_PROJECT_ID;
    const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
    const privateKey = createPrivateKey(process.env.FIREBASE_PRIVATE_KEY);
    const resolvedProjectId = projectId || 'lumi-dev';

    if (emulatorMode) {
      firebaseApp = admin.initializeApp({
        projectId: resolvedProjectId,
      });
      return firebaseApp;
    }

    if (serviceAccountPath) {
      firebaseApp = admin.initializeApp({
        credential: createCredentialFromServiceAccountPath(serviceAccountPath),
        projectId: resolvedProjectId,
      });
      return firebaseApp;
    }

    if (projectId && clientEmail && privateKey) {
      firebaseApp = admin.initializeApp({
        credential: admin.credential.cert({
          projectId,
          clientEmail,
          privateKey,
        }),
        projectId,
      });
      return firebaseApp;
    }

    firebaseApp = admin.initializeApp({
      projectId: resolvedProjectId,
    });
    return firebaseApp;
  } catch (error) {
    console.warn('Firebase Admin initialization skipped:', error.message);
    return null;
  }
}

initializeFirebase();

function assertFirebaseReady() {
  const appInstance = initializeFirebase();

  if (!appInstance) {
    throw new Error(
      'Firebase Admin is not configured. Set FIREBASE_SERVICE_ACCOUNT_PATH or FIREBASE_* env vars in backend_api/.env',
    );
  }

  return appInstance;
}

export function getAuth() {
  assertFirebaseReady();

  return admin.auth();
}

export function getFirestore() {
  assertFirebaseReady();

  return admin.firestore();
}

export function isFirebaseReady() {
  return Boolean(initializeFirebase());
}

export default admin;
