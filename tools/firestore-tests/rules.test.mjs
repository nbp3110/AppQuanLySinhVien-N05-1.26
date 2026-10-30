import { before, after, beforeEach, test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc, deleteDoc, writeBatch, increment } from 'firebase/firestore';

let env;
const student = { name: 'Sinh viên mẫu', major: 'CNTT', age: 21, classId: 'CNTT01', email: '', gradeCount: 0 };
const grade = { studentId: 'SV1', subjectId: 'M1', semester: '2026-1', score: 8.5 };
before(async () => {
  env = await initializeTestEnvironment({projectId: 'demo-qlsv', firestore: {
    rules: readFileSync(new URL('../../firestore.rules', import.meta.url), 'utf8'),
  }});
});
after(async () => { await env?.cleanup(); });
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'users/manager'), { email: 'manager@example.com', displayName: 'Quản lý', role: 'manager' });
    await setDoc(doc(db, 'classes/CNTT01'), {name: 'CNTT 01', major: 'CNTT', cohort: 'K17'});
    await setDoc(doc(db, 'students/SV1'), student);
    await setDoc(doc(db, 'subjects/M1'), {name: 'Di động', credits: 3});
  });
});
const manager = () => env.authenticatedContext('manager').firestore();
test('Unauthenticated users cannot read or write student data', async () => {
  const db = env.unauthenticatedContext().firestore();
  await assertFails(getDoc(doc(db, 'students/SV1')));
  await assertFails(setDoc(doc(db, 'students/SV2'), student));
});
test('Signing in alone does not grant manager access or allow self-promotion', async () => {
  const db = env.authenticatedContext('outsider').firestore();
  await assertFails(getDoc(doc(db, 'students/SV1')));
  await assertFails(setDoc(doc(db, 'users/outsider'), {email: 'o@example.com', displayName: 'O', role: 'manager'}));
});
test('Manager can read and write valid data in all academic collections', async () => {
  const db = manager();
  await assertSucceeds(getDoc(doc(db, 'students/SV1')));
  await assertSucceeds(setDoc(doc(db, 'students/SV2'), student));
  await assertSucceeds(setDoc(doc(db, 'classes/CNTT02'), {name: 'CNTT 02', major: 'CNTT', cohort: 'K17'}));
  await assertSucceeds(setDoc(doc(db, 'subjects/M2'), {name: 'CSDL', credits: 3}));
  const batch = writeBatch(db);
  batch.set(doc(db, 'grades/SV1~M1~2026-1'), grade);
  batch.update(doc(db, 'students/SV1'), { gradeCount: increment(1) });
  await assertSucceeds(batch.commit());
});
test('Reject malformed documents, invalid scores and broken references', async () => {
  const db = manager();
  await assertFails(setDoc(doc(db, 'students/SV2'), {...student, classId: 'MISSING'}));
  await assertFails(setDoc(doc(db, 'students/SV2'), {...student, age: -1}));
  await assertFails(setDoc(doc(db, 'students/SV2'), {...student, name: '   '}));
  await assertFails(setDoc(doc(db, 'students/SV2'), {...student, secret: 'unexpected'}));
  await assertFails(setDoc(doc(db, 'subjects/M2'), {name: 'CSDL', credits: 1.5}));
  const withCounter = async (id, data, studentId) => {
    const batch = writeBatch(db);
    batch.set(doc(db, `grades/${id}`), data);
    batch.update(doc(db, `students/${studentId}`), { gradeCount: increment(1) });
    return batch.commit();
  };
  await assertFails(withCounter('SV1~M1~2026-1', {...grade, score: 11}, 'SV1'));
  await assertFails(withCounter('SV2~M1~2026-1', {...grade, studentId: 'SV2'}, 'SV1'));
  await assertFails(withCounter('wrong-id', grade, 'SV1'));
  await assertFails(setDoc(doc(db, 'students/SV3'), {...student, gradeCount: 5}));
  await assertFails(setDoc(doc(db, 'students/SV4'), (({gradeCount, ...rest}) => rest)(student)));
});
test('Managers may change their name but not permissions or other profiles', async () => {
  const db = manager();
  await assertSucceeds(updateDoc(doc(db, 'users/manager'), {displayName: 'Tên mới'}));
  await assertFails(updateDoc(doc(db, 'users/manager'), {role: 'admin'}));
  await assertFails(updateDoc(doc(db, 'users/manager'), {email: 'other@example.com'}));
  await assertFails(setDoc(doc(db, 'users/other'), {displayName: 'Other', email: 'o@example.com', role: 'manager'}));
});
test('A student without grades can be deleted by a manager only', async () => {
  await assertSucceeds(deleteDoc(doc(manager(), 'students/SV1')));
  await env.withSecurityRulesDisabled(ctx => setDoc(doc(ctx.firestore(), 'students/SV9'), student));
  await assertFails(deleteDoc(doc(env.unauthenticatedContext().firestore(), 'students/SV9')));
  await assertFails(deleteDoc(doc(env.authenticatedContext('outsider').firestore(), 'students/SV9')));
});
test('A student with grades cannot be deleted', async () => {
  const db = manager();
  const batch = writeBatch(db);
  batch.set(doc(db, 'grades/SV1~M1~2026-1'), grade);
  batch.update(doc(db, 'students/SV1'), { gradeCount: increment(1) });
  await assertSucceeds(batch.commit());
  await assertFails(deleteDoc(doc(db, 'students/SV1')));
  assert.equal((await getDoc(doc(db, 'students/SV1'))).exists(), true);
});
test('A grade is refused unless the student counter rises by exactly one with it', async () => {
  const db = manager();
  await assertFails(setDoc(doc(db, 'grades/SV1~M1~2026-1'), grade));
  const twice = writeBatch(db);
  twice.set(doc(db, 'grades/SV1~M1~2026-1'), grade);
  twice.update(doc(db, 'students/SV1'), { gradeCount: increment(2) });
  await assertFails(twice.commit());
  assert.equal((await getDoc(doc(db, 'grades/SV1~M1~2026-1'))).exists(), false);
});
test('Editing a grade again does not need the counter', async () => {
  const db = manager();
  const batch = writeBatch(db);
  batch.set(doc(db, 'grades/SV1~M1~2026-1'), grade);
  batch.update(doc(db, 'students/SV1'), { gradeCount: increment(1) });
  await assertSucceeds(batch.commit());
  await assertSucceeds(setDoc(doc(db, 'grades/SV1~M1~2026-1'), {...grade, score: 9}));
});
test('The grade counter cannot be lowered or changed together with the profile', async () => {
  const db = manager();
  const batch = writeBatch(db);
  batch.set(doc(db, 'grades/SV1~M1~2026-1'), grade);
  batch.update(doc(db, 'students/SV1'), { gradeCount: increment(1) });
  await assertSucceeds(batch.commit());
  await assertFails(updateDoc(doc(db, 'students/SV1'), { gradeCount: 0 }));
  await assertFails(updateDoc(doc(db, 'students/SV1'), { gradeCount: 2, name: 'Tên khác' }));
  await assertSucceeds(updateDoc(doc(db, 'students/SV1'), { name: 'Tên khác' }));
});
test('Grades, classes and subjects can still not be deleted', async () => {
  const db = manager();
  await assertFails(deleteDoc(doc(db, 'classes/CNTT01')));
  await assertFails(deleteDoc(doc(db, 'subjects/M1')));
});
