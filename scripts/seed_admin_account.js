/**
 * Parkiko Administrative Seeding Script
 * 
 * Provisions the initial Parkiko Admin account:
 * - User ID: admin1
 * - Initial Password: 1234
 * - Firestore User Profile: users/{uid}
 * - Role: ADMIN, Status: ACTIVE
 *
 * Usage: node scripts/seed_admin_account.js
 */

const fs = require('fs');
const os = require('os');
const path = require('path');
const https = require('https');
const crypto = require('crypto');

const PROJECT_ID = 'parkiko-cd383';
const WEB_API_KEY = 'AIzaSyCDGZwcHeiUPyLHu1YjrTWW6ncvuhYtnW8';
const DEFAULT_USER_ID = 'admin1';
const DEFAULT_PASSWORD = '1234';
const TENANT_DOMAIN = 'auth.parkiko.internal';

function getAccessToken() {
  try {
    const configPath = path.join(os.homedir(), '.config', 'configstore', 'firebase-tools.json');
    if (fs.existsSync(configPath)) {
      const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
      return config.tokens?.access_token;
    }
  } catch (_) {}
  return null;
}

function deriveAuthPassword(userId, rawPassword) {
  if (rawPassword.length >= 6) return rawPassword;
  const salt = `parkiko-sec-tenant-${userId.toLowerCase().trim()}-v1`;
  const hmac = crypto.createHmac('sha256', salt);
  hmac.update(rawPassword);
  return hmac.digest('hex');
}

function httpRequest(options, postData) {
  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        try {
          const json = body ? JSON.parse(body) : {};
          resolve({ status: res.statusCode, data: json, raw: body });
        } catch (e) {
          resolve({ status: res.statusCode, raw: body });
        }
      });
    });
    req.on('error', reject);
    if (postData) req.write(typeof postData === 'string' ? postData : JSON.stringify(postData));
    req.end();
  });
}

async function createAuthUser(email, password) {
  console.log(`\n[1/3] Creating Firebase Authentication user: ${email}...`);
  const payload = {
    email: email,
    password: password,
    returnSecureToken: true
  };

  const res = await httpRequest({
    hostname: 'identitytoolkit.googleapis.com',
    path: `/v1/accounts:signUp?key=${WEB_API_KEY}`,
    method: 'POST',
    headers: { 'Content-Type': 'application/json' }
  }, payload);

  if (res.status === 200 && res.data.localId) {
    console.log(`✓ Firebase Auth account created successfully!`);
    console.log(`  Firebase UID: ${res.data.localId}`);
    return res.data.localId;
  }

  if (res.data?.error?.message === 'EMAIL_EXISTS') {
    console.log(`ℹ Account already exists in Firebase Auth. Signing in to retrieve UID...`);
    const signInRes = await httpRequest({
      hostname: 'identitytoolkit.googleapis.com',
      path: `/v1/accounts:signInWithPassword?key=${WEB_API_KEY}`,
      method: 'POST',
      headers: { 'Content-Type': 'application/json' }
    }, payload);

    if (signInRes.status === 200 && signInRes.data.localId) {
      console.log(`✓ Existing Firebase UID retrieved: ${signInRes.data.localId}`);
      return signInRes.data.localId;
    }
  }

  if (res.data?.error?.message === 'CONFIGURATION_NOT_FOUND') {
    console.warn(`\n[!] Firebase Authentication has not been activated in Firebase Console yet.`);
    console.warn(`    Action Required: Go to https://console.firebase.google.com/project/${PROJECT_ID}/authentication`);
    console.warn(`    Click 'Get started', and enable 'Email/Password' under the Sign-in method tab.`);
    return null;
  }

  console.error(`Error creating Auth user:`, res.data || res.raw);
  return null;
}

async function writeFirestoreProfile(token, uid, userId) {
  console.log(`\n[2/3] Writing Firestore user profile at users/${uid}...`);
  const nowIso = new Date().toISOString();

  const profileDoc = {
    fields: {
      uid: { stringValue: uid },
      userId: { stringValue: userId },
      name: { stringValue: 'Parkiko Admin' },
      role: { stringValue: 'ADMIN' },
      status: { stringValue: 'ACTIVE' },
      organizationId: { nullValue: null },
      locationIds: { arrayValue: { values: [] } },
      createdAt: { timestampValue: nowIso },
      updatedAt: { timestampValue: nowIso }
    }
  };

  const headers = { 'Content-Type': 'application/json' };
  if (token) headers['Authorization'] = `Bearer ${token}`;

  const res = await httpRequest({
    hostname: 'firestore.googleapis.com',
    path: `/v1/projects/${PROJECT_ID}/databases/(default)/documents/users/${uid}`,
    method: 'PATCH',
    headers
  }, profileDoc);

  if (res.status === 200) {
    console.log(`✓ Firestore user profile created at users/${uid}!`);
    console.log(`  Fields: role=ADMIN, status=ACTIVE, userId=${userId}`);
  } else {
    console.error(`Failed to write Firestore profile (status ${res.status}):`, res.data || res.raw);
  }

  // Also create user mapping for fast lookups
  console.log(`\n[3/3] Writing mapping record at user_mappings/${userId}...`);
  const mappingDoc = {
    fields: {
      userId: { stringValue: userId },
      email: { stringValue: `${userId}@${TENANT_DOMAIN}` },
      uid: { stringValue: uid }
    }
  };

  const mapRes = await httpRequest({
    hostname: 'firestore.googleapis.com',
    path: `/v1/projects/${PROJECT_ID}/databases/(default)/documents/user_mappings/${userId}`,
    method: 'PATCH',
    headers
  }, mappingDoc);

  if (mapRes.status === 200) {
    console.log(`✓ User ID mapping created at user_mappings/${userId}!`);
  }
}

async function main() {
  console.log(`=== PARKIKO ADMIN ACCOUNT PROVISIONING ===`);
  console.log(`Project ID: ${PROJECT_ID}`);
  console.log(`Target User ID: ${DEFAULT_USER_ID}`);
  
  const email = `${DEFAULT_USER_ID}@${TENANT_DOMAIN}`;
  const authPassword = deriveAuthPassword(DEFAULT_USER_ID, DEFAULT_PASSWORD);
  const token = getAccessToken();

  const uid = await createAuthUser(email, authPassword);

  if (uid) {
    await writeFirestoreProfile(token, uid, DEFAULT_USER_ID);
    console.log(`\n=== PROVISIONING COMPLETED SUCCESSFULLY ===`);
  } else {
    // Generate an authoritative deterministic placeholder UID for initial Firestore record if Auth is pending console activation
    const fallbackUid = crypto.createHash('sha256').update(email).digest('hex').substring(0, 28);
    console.log(`\nPre-seeding Firestore profile with reference UID: ${fallbackUid}`);
    await writeFirestoreProfile(token, fallbackUid, DEFAULT_USER_ID);
    console.log(`\nOnce Email/Password is enabled in the Firebase Console, run this script again to finalize the Auth UID!`);
  }
}

main().catch(console.error);
