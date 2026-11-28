// SmartCart · HU-23 · Envío de notificaciones push (Firebase Cloud Messaging)
//
// La llama un Database Webhook de Supabase cada vez que se inserta una fila
// en public.notificacion (el trigger de sprint3_hu23.sql la crea cuando
// cambia el estado de una orden). Lee los tokens del usuario en
// public.dispositivo_push y le envía el aviso a cada teléfono con la API
// HTTP v1 de FCM. Los tokens que FCM ya no reconoce se borran.
//
// Secretos que hay que configurar (supabase secrets set ...):
//   FIREBASE_SERVICE_ACCOUNT  JSON de la cuenta de servicio de Firebase
//   WEBHOOK_SECRET            el mismo valor que se pone en el encabezado
//                             "x-webhook-secret" del Database Webhook
// SUPABASE_URL y SUPABASE_SERVICE_ROLE_KEY los pone Supabase solo.
// Pasos completos en docs/HU23_informe_implementacion.md.

import { createClient } from "npm:@supabase/supabase-js@2.45.4";

interface Notificacion {
  id_notificacion: number;
  id_usuario: string;
  titulo: string;
  mensaje: string;
}

interface CuentaServicio {
  project_id: string;
  client_email: string;
  private_key: string;
}

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Método no permitido", { status: 405 });
  }
  // Solo el webhook de la base conoce este secreto.
  const secreto = Deno.env.get("WEBHOOK_SECRET");
  if (!secreto || req.headers.get("x-webhook-secret") !== secreto) {
    return new Response("No autorizado", { status: 401 });
  }

  const cuerpo = await req.json();
  if (cuerpo?.type !== "INSERT" || cuerpo?.table !== "notificacion") {
    return Response.json({ enviados: 0, motivo: "evento ignorado" });
  }
  const aviso = cuerpo.record as Notificacion;

  const { data: dispositivos, error } = await supabase
    .from("dispositivo_push")
    .select("token")
    .eq("id_usuario", aviso.id_usuario);
  if (error) {
    return Response.json({ error: error.message }, { status: 500 });
  }
  if (!dispositivos || dispositivos.length === 0) {
    return Response.json({ enviados: 0, motivo: "sin dispositivos" });
  }

  const cuenta = JSON.parse(
    Deno.env.get("FIREBASE_SERVICE_ACCOUNT")!,
  ) as CuentaServicio;
  const accessToken = await tokenDeAcceso(cuenta);

  let enviados = 0;
  const vencidos: string[] = [];
  for (const { token } of dispositivos) {
    const respuesta = await fetch(
      `https://fcm.googleapis.com/v1/projects/${cuenta.project_id}/messages:send`,
      {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          message: {
            token,
            notification: { title: aviso.titulo, body: aviso.mensaje },
            // La app abre "Mis órdenes" al tocar el aviso.
            data: { tipo: "orden", id_notificacion: String(aviso.id_notificacion) },
            android: {
              priority: "HIGH",
              notification: { channel_id: "ordenes" },
            },
          },
        }),
      },
    );
    if (respuesta.ok) {
      enviados++;
    } else if (respuesta.status === 404 || respuesta.status === 400) {
      // UNREGISTERED o INVALID_ARGUMENT: el token ya no sirve.
      vencidos.push(token);
    }
  }
  if (vencidos.length > 0) {
    await supabase.from("dispositivo_push").delete().in("token", vencidos);
  }
  return Response.json({ enviados, vencidos: vencidos.length });
});

/// Token OAuth de Google para FCM, firmado con la llave de la cuenta de
/// servicio (JWT RS256), sin dependencias extra.
async function tokenDeAcceso(cuenta: CuentaServicio): Promise<string> {
  const ahora = Math.floor(Date.now() / 1000);
  const encabezado = { alg: "RS256", typ: "JWT" };
  const reclamos = {
    iss: cuenta.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: ahora,
    exp: ahora + 3600,
  };
  const base64url = (datos: Uint8Array | string) => {
    const bytes = typeof datos === "string"
      ? new TextEncoder().encode(datos)
      : datos;
    return btoa(String.fromCharCode(...bytes))
      .replace(/=+$/, "").replace(/\+/g, "-").replace(/\//g, "_");
  };
  const sinFirmar = `${base64url(JSON.stringify(encabezado))}.${
    base64url(JSON.stringify(reclamos))
  }`;

  const pem = cuenta.private_key
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s/g, "");
  const llave = await crypto.subtle.importKey(
    "pkcs8",
    Uint8Array.from(atob(pem), (c) => c.charCodeAt(0)),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const firma = new Uint8Array(
    await crypto.subtle.sign(
      "RSASSA-PKCS1-v1_5",
      llave,
      new TextEncoder().encode(sinFirmar),
    ),
  );

  const respuesta = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: `${sinFirmar}.${base64url(firma)}`,
    }),
  });
  const json = await respuesta.json();
  if (!json.access_token) {
    throw new Error(`Google no entregó el token de acceso: ${JSON.stringify(json)}`);
  }
  return json.access_token as string;
}
