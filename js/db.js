import { FIREBASE_CONFIG, DB_PATH } from "./config.js";

let firebaseDb = null;
let unsubscribe = null;
export function isFirebaseConfigured() { return !FIREBASE_CONFIG.apiKey.startsWith("REEMPLAZAR") && !FIREBASE_CONFIG.databaseURL.includes("REEMPLAZAR"); }
export async function subscribeToReadings(onChange, onError) {
  if (!isFirebaseConfigured()) { onError(new Error("Firebase no está configurado")); return () => {}; }
  try {
    const [{ initializeApp }, { getDatabase, ref, onValue }] = await Promise.all([
      import("https://www.gstatic.com/firebasejs/11.0.2/firebase-app.js"),
      import("https://www.gstatic.com/firebasejs/11.0.2/firebase-database.js")
    ]);
    firebaseDb = getDatabase(initializeApp(FIREBASE_CONFIG));
    const readingsRef = ref(firebaseDb, DB_PATH);
    unsubscribe = onValue(readingsRef, snapshot => onChange(snapshot.val() || {}), error => onError(error));
    return unsubscribe;
  } catch (error) { onError(error); return () => {}; }
}
export function stopSubscription() { if (unsubscribe) unsubscribe(); unsubscribe = null; }
