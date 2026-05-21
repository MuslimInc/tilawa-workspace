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
export const verifySupportPurchase = onCall(
  { region: "us-central1" },
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

    const tokenHash = createHash("sha256").update(purchaseToken).digest("hex");
    const db = getFirestore();
    const ledgerRef = db.collection("support_purchases").doc(tokenHash);
    const existing = await ledgerRef.get();

    if (existing.exists) {
      const stored = existing.data();
      return {
        verified: true,
        orderId: (stored?.orderId as string) ?? "",
        productId: (stored?.productId as string) ?? productId,
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

    const orderId = purchase.data.orderId ?? "";

    await ledgerRef.set({
      productId,
      orderId,
      packageName,
      verifiedAt: FieldValue.serverTimestamp(),
    });

    return {
      verified: true,
      orderId,
      productId,
    };
  }
);
