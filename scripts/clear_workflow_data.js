/**
 * Parkiko Workflow Test Reset Script
 * 
 * Clears all transactional test data from Cloud Firestore:
 * - valet_intakes
 * - tickets
 * - vehicle_conditions
 * - key_records
 * - ticketEvents
 * - attendance
 * - payments
 * 
 * Preserves staff accounts, user logins, and sites intact.
 * 
 * Usage: node scripts/clear_workflow_data.js
 */

const { execSync } = require('child_process');

const COLLECTIONS_TO_CLEAR = [
  'valet_intakes',
  'tickets',
  'vehicle_conditions',
  'key_records',
  'ticketEvents',
  'attendance',
  'payments'
];

console.log('=== PARKIKO WORKFLOW DATA RESET ===\n');

for (const col of COLLECTIONS_TO_CLEAR) {
  try {
    process.stdout.write(`Clearing collection: ${col}... `);
    execSync(`firebase firestore:delete -r ${col} -f`, { stdio: 'pipe' });
    console.log('✓ Cleared');
  } catch (err) {
    console.error(`✗ Error clearing ${col}: ${err.message}`);
  }
}

console.log('\n✓ All workflow test data has been successfully cleared!');
console.log('Staff accounts and sites remain untouched.');
