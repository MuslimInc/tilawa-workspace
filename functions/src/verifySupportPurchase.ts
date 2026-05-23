import { createHash } from "crypto";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { google } from "googleapis";

interface VerifySupportPurchaseRequest {
  productId?: string;
  purchaseToken?: string;
  packageName?: string;
}

interface VerifySupportPurchaseResponse {
  verified: boolean;
  orderId: string;
  productId: string;
}

const ALLOWED_PRODUCTS = new Set([
  "support_once_small",
  "support_once_kind",
  "support_once_generous",
]);

const DEFAULT_PACKAGE = "com.tilawa.app";

/**
 * Verifies a one-time Google Play consumable support purchase.
 * Logs purchaseToken hash for replay protection (no entitlement mirror in MVP).
 */
// Requires firebase_app_check in the Flutter app (Play Integrity on release
// builds) and App Check enabled in Firebase Console. See docs/support_play_products.md.
export const verifySupportPurchase = onCall(
  { region: "us-central1", enforceAppCheck: true },
  async (request): Promise<VerifySupportPurchaseResponse> => {
    const data = request.data as VerifySupportPurchaseRequest;
    const productId = data.productId?.trim();
    const purchaseToken = data.purchaseToken?.trim();
    const packageName = data.packageName?.trim() || DEFAULT_PACKAGE;

    if (!productId || !purchaseToken) {
      throw new HttpsError(
        "invalid-argument",
        "productId and purchaseToken are required."
      );
    }

    if (!ALLOWED_PRODUCTS.has(productId)) {
      throw new HttpsError("invalid-argument", "Unknown productId.");
    }

    if (packageName !== DEFAULT_PACKAGE) {
      throw new HttpsError("invalid-argument", "Unknown packageName.");
    }

    const tokenHash = createHash("sha256").update(purchaseToken).digest("hex");
    const db = getFirestore();
    const ledgerRef = db.collection("support_purchases").doc(tokenHash);
    const existing = await ledgerRef.get();

    if (existing.exists) {
      const stored = existing.data();
      const storedProductId = (stored?.productId as string) ?? "";
      // Token belongs to a different product than the client claims — refuse
      // so a leaked token can't be replayed against a different SKU.
      if (storedProductId && storedProductId !== productId) {
        throw new HttpsError(
          "permission-denied",
          "Token does not belong to this productId."
        );
      }
      return {
        verified: true,
        orderId: (stored?.orderId as string) ?? "",
        productId: storedProductId || productId,
      };
    }

    const auth = await google.auth.getClient({
      scopes: ["https://www.googleapis.com/auth/androidpublisher"],
    });
    const androidPublisher = google.androidpublisher({
      version: "v3",
      auth,
    });

    const purchase = await androidPublisher.purchases.products.get({
      packageName,
      productId,
      token: purchaseToken,
    });

    const purchaseState = purchase.data.purchaseState;
    // 0 = purchased
    if (purchaseState !== 0) {
      throw new HttpsError(
        "failed-precondition",
        `Purchase not completed (state=${purchaseState}).`
      );
    }

    // androidpublisher.purchases.products.get returns purchase metadata for
    // the (packageName, productId, token) triple. If the SKU does not match,
    // Google returns 404 — but be defensive and confirm any returned
    // productId equals what we asked for before trusting it downstream.
    const verifiedProductId =
      (purchase.data as { productId?: string }).productId ?? productId;
    if (verifiedProductId !== productId) {
      throw new HttpsError(
        "permission-denied",
        "Token does not belong to this productId."
      );
    }

    const orderId = purchase.data.orderId ?? "";

    await ledgerRef.set({
      productId: verifiedProductId,
      orderId,
      packageName,
      verifiedAt: FieldValue.serverTimestamp(),
    });

    return {
      verified: true,
      orderId,
      productId: verifiedProductId,
    };
  }
);
