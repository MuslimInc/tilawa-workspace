import { initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { FIREBASE_PROJECT_ID } from '../src/github';

async function main() {
  initializeApp({ projectId: FIREBASE_PROJECT_ID });
  const auth = getAuth();
  const db = getFirestore();
  
  try {
    const user = await auth.getUserByEmail('mu7ammadkamel@hotmail.com');
    const uid = user.uid;
    console.log(`Teacher UID: ${uid}`);
    
    // Create teacher profile if it doesn't exist
    const teacherRef = db.collection('quran_teacher_profiles').doc(uid);
    const doc = await teacherRef.get();
    if (!doc.exists) {
      console.log('Creating teacher profile...');
      await teacherRef.set({
        verificationStatus: "verified",
        gender: "male",
        allowedStudentGender: "both",
        canTeachChildren: true,
        discoverable: true,
      });
      console.log('Teacher profile created.');
    } else {
      console.log('Teacher profile already exists.');
    }
  } catch (error) {
    console.error('Error:', error);
  }
}
main().catch(console.error);
