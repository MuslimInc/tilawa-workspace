import test from "node:test";
import assert from "node:assert/strict";

import { runIdempotentOperation } from "../src/quranSessions/idempotencyService";
import { clearFirestore, db } from "./support/emulator";

test("integration: idempotent op reads then writes and commits against real Firestore", async () => {
  await clearFirestore();
  const firestore = db();
  const bookingRef = firestore.collection("quran_bookings").doc("b1");
  await bookingRef.set({ lifecycleStatus: "disputed" });

  // execute reads the booking THEN writes — the exact ordering that threw under
  // the old (pending-marker-first) implementation. It must now commit cleanly.
  const { replayed, result } = await runIdempotentOperation(
    {
      db: firestore,
      operationKey: "issue_refund:b1:default",
      actorId: "admin1",
      action: "issue_refund",
    },
    async (tx) => {
      const snap = await tx.get(bookingRef);
      assert.equal(snap.get("lifecycleStatus"), "disputed");
      tx.set(bookingRef, { lifecycleStatus: "refunded" }, { merge: true });
      return { lifecycleStatus: "refunded" };
    },
  );

  assert.equal(replayed, false);
  assert.equal(result.lifecycleStatus, "refunded");

  const after = await bookingRef.get();
  assert.equal(after.get("lifecycleStatus"), "refunded");

  const marker = await firestore
    .collection("quran_session_operations")
    .doc("issue_refund:b1:default")
    .get();
  assert.equal(marker.get("status"), "completed");
});

test("integration: duplicate operation replays without repeating the side effect", async () => {
  await clearFirestore();
  const firestore = db();
  const bookingRef = firestore.collection("quran_bookings").doc("b1");
  await bookingRef.set({ counter: 0 });
  let executeCount = 0;

  const run = () =>
    runIdempotentOperation(
      { db: firestore, operationKey: "op:b1:default", actorId: "a", action: "op" },
      async (tx) => {
        const snap = await tx.get(bookingRef);
        executeCount += 1;
        tx.set(
          bookingRef,
          { counter: ((snap.get("counter") as number) ?? 0) + 1 },
          { merge: true },
        );
        return { ran: executeCount };
      },
    );

  const first = await run();
  const second = await run();

  assert.equal(first.replayed, false);
  assert.equal(second.replayed, true);
  assert.equal(executeCount, 1);

  const after = await bookingRef.get();
  assert.equal(after.get("counter"), 1);
});

test("integration: real Firestore rejects read-after-write (proves the original defect)", async () => {
  await clearFirestore();
  const firestore = db();
  const bookingRef = firestore.collection("quran_bookings").doc("b1");
  const markerRef = firestore.collection("quran_session_operations").doc("bug");
  await bookingRef.set({ lifecycleStatus: "disputed" });

  await assert.rejects(
    firestore.runTransaction(async (tx) => {
      tx.set(markerRef, { status: "pending" }); // WRITE first (old ordering)
      await tx.get(bookingRef); // READ after write — must throw
    }),
    /all reads.*before all writes/i,
  );
});
