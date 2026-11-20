import {initializeApp} from "firebase-admin/app";
import {FieldValue, getFirestore, Timestamp} from "firebase-admin/firestore";
import {HttpsError, onCall} from "firebase-functions/v2/https";

initializeApp();

const db = getFirestore();
const supportEmail = "nsala932@gmail.com";
const allowedCategories = new Set([
  "Conducta antideportiva",
  "Acoso o amenazas",
  "Perfil falso",
  "Otro",
]);

function markdownSafe(value: string): string {
  return value.replace(/([\\`*_{}\[\]\(\)#+.!|>~-])/g, "\\$1");
}

export const submitPlayerReport = onCall(
  {enforceAppCheck: true, region: "southamerica-east1"},
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Debes iniciar sesión para reportar.");
    }
    const reporterId = request.auth.uid;
    const phone = request.auth.token.phone_number;
    if (typeof phone !== "string" || phone.length === 0) {
      throw new HttpsError("failed-precondition", "La cuenta necesita un teléfono verificado.");
    }

    const reportedId = request.data?.reportedPlayerId;
    const category = request.data?.category;
    const details = request.data?.details;
    const context = request.data?.context ?? "";
    if (typeof reportedId !== "string" || reportedId === reporterId) {
      throw new HttpsError("invalid-argument", "El jugador reportado no es válido.");
    }
    if (typeof category !== "string" || !allowedCategories.has(category)) {
      throw new HttpsError("invalid-argument", "Selecciona un motivo válido.");
    }
    if (typeof details !== "string" || details.trim().length < 10 || details.length > 4000) {
      throw new HttpsError("invalid-argument", "El detalle debe tener entre 10 y 4000 caracteres.");
    }
    if (typeof context !== "string" || context.length > 1000) {
      throw new HttpsError("invalid-argument", "El contexto no puede superar los 1000 caracteres.");
    }

    const [reporterSnapshot, reportedSnapshot] = await Promise.all([
      db.collection("users").doc(reporterId).get(),
      db.collection("users").doc(reportedId).get(),
    ]);
    if (!reporterSnapshot.exists || !reportedSnapshot.exists) {
      throw new HttpsError("not-found", "No se encontró el perfil de uno de los jugadores.");
    }

    const day = new Date().toISOString().slice(0, 10);
    const limitRef = db.collection("users").doc(reporterId).collection("reportLimits").doc(day);
    const reportRef = db.collection("reports").doc();
    const mailRef = db.collection("mail").doc(reportRef.id);
    const reporter = reporterSnapshot.data()!;
    const reported = reportedSnapshot.data()!;
    const createdAt = Timestamp.now();
    const markdown = [
      "# Reporte de jugador — Hay Equipo",
      "",
      `- **Fecha (UTC):** ${createdAt.toDate().toISOString()}`,
      `- **Reportante:** ${markdownSafe(String(reporter.name ?? "Jugador"))} (${reporterId})`,
      `- **Teléfono verificado:** ${markdownSafe(phone)}`,
      `- **Jugador reportado:** ${markdownSafe(String(reported.name ?? "Jugador"))} (${reportedId})`,
      `- **Motivo:** ${markdownSafe(category)}`,
      "",
      "## Contexto",
      context.trim() ? markdownSafe(context.trim()) : "_No indicado._",
      "",
      "## Descripción del incidente",
      markdownSafe(details.trim()),
    ].join("\n");

    await db.runTransaction(async (transaction) => {
      const limitSnapshot = await transaction.get(limitRef);
      const count = Number(limitSnapshot.data()?.count ?? 0);
      if (count >= 5) {
        throw new HttpsError("resource-exhausted", "Alcanzaste el límite diario de reportes.");
      }
      transaction.set(limitRef, {
        count: count + 1,
        updatedAt: FieldValue.serverTimestamp(),
      });
      transaction.create(reportRef, {
        reporterId,
        reportedPlayerId: reportedId,
        category,
        details: details.trim(),
        context: context.trim(),
        createdAt,
        status: "received",
      });
      transaction.create(mailRef, {
        to: [supportEmail],
        message: {
          subject: `Reporte de jugador - ${String(reported.name ?? "Jugador")}`,
          text: markdown,
        },
      });
    });

    return {reportId: reportRef.id};
  },
);
