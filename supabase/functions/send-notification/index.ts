// // Supabase runtime types for Edge Functions
// import "jsr:@supabase/functions-js/edge-runtime.d.ts";
// import { createClient } from "@supabase/supabase-js";
// import { SignJWT, importPKCS8 } from "npm:jose";

// // --- Supabase client
// const supabaseUrl = Deno.env.get("PROJECT_URL")!;
// const supabaseKey = Deno.env.get("SERVICE_ROLE_KEY")!;
// const supabase = createClient(supabaseUrl, supabaseKey);

// // --- Firebase service account (read from secrets)
// const serviceAccount = {
//   project_id: "dopashorts-2fdaf",
//   private_key_id: Deno.env.get("FIREBASE_PRIVATE_KEY_ID")!,
//   private_key: Deno.env.get("FIREBASE_PRIVATE_KEY")!,
//   client_email: Deno.env.get("FIREBASE_CLIENT_EMAIL")!,
//   client_id: Deno.env.get("FIREBASE_CLIENT_ID")!,
//   token_uri: "https://oauth2.googleapis.com/token",
// };

// // --- Function to get Firebase OAuth2 access token
// async function getAccessToken() {
//   const now = Math.floor(Date.now() / 1000);

//   const payload = {
//     iss: serviceAccount.client_email,
//     scope: "https://www.googleapis.com/auth/firebase.messaging",
//     aud: serviceAccount.token_uri,
//     iat: now,
//     exp: now + 3600,
//   };

//   // 🔑 Fix: clean PEM string (remove quotes/escapes)
//   const pemKey = serviceAccount.private_key
//     .replace(/\\n/g, "\n") // handle escaped \n if present
//     .replace(/-----BEGIN PRIVATE KEY-----/, "-----BEGIN PRIVATE KEY-----\n")
//     .replace(/-----END PRIVATE KEY-----/, "\n-----END PRIVATE KEY-----")
//     .trim();

//   const privateKey = await importPKCS8(pemKey, "RS256");

//   const jwt = await new SignJWT(payload)
//     .setProtectedHeader({ alg: "RS256", typ: "JWT" })
//     .sign(privateKey);

//   const resp = await fetch(serviceAccount.token_uri, {
//     method: "POST",
//     headers: { "Content-Type": "application/x-www-form-urlencoded" },
//     body: new URLSearchParams({
//       grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
//       assertion: jwt,
//     }),
//   });

//   const { access_token, error } = await resp.json();
//   if (!access_token) {
//     console.error("❌ Failed to fetch Firebase access token:", error);
//     throw new Error("Failed to fetch Firebase access token");
//   }
//   return access_token;
// }

// // --- Edge Function handler
// Deno.serve(async (req) => {
//   try {
//     const { event, follower_id, following_id } = await req.json();

//     if (event !== "follow") {
//       return new Response("Invalid event", { status: 400 });
//     }

//     console.log("📨 New follow event:", { follower_id, following_id });

//     // --- Get follower name
//     const { data: followerData } = await supabase
//       .from("users")
//       .select("username")
//       .eq("id", String(follower_id).trim())
//       .single();

//     const followerName = followerData?.username || "Someone";

//     // --- Get device tokens of the user being followed
//     const { data: tokensData, error: tokenError } = await supabase
//       .from("user_tokens")
//       .select("token")
//       .eq("user_id", String(following_id).trim());

//     if (tokenError) {
//       console.error("❌ Token query error:", tokenError);
//       return new Response("Database error", { status: 500 });
//     }

//     if (!tokensData || tokensData.length === 0) {
//       console.log("⚠️ No tokens found for user", following_id);
//       return new Response("No tokens found", { status: 200 });
//     }

//     console.log("✅ Tokens found:", tokensData.map((t) => t.token));

//     // --- Get Firebase access token
//     const accessToken = await getAccessToken();

//     // --- Send FCM notification to each token
//     for (const row of tokensData) {
//       const fcmResp = await fetch(
//         `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`,
//         {
//           method: "POST",
//           headers: {
//             Authorization: `Bearer ${accessToken}`,
//             "Content-Type": "application/json",
//           },
//           body: JSON.stringify({
//             message: {
//               token: row.token,
//               notification: {
//                 title: "New Follower",
//                 body: `${followerName} started following you`,
//               },
//               data: {
//                 follower_id: String(follower_id),
//                 event: "follow",
//               },
//               android: {
//                 priority: "high",
//                 notification: {
//                   channel_id: "high_importance_channel",
//                   sound: "default",
//                 },
//               },
//               apns: {
//                 payload: {
//                   aps: {
//                     sound: "default",
//                     contentAvailable: true,
//                   },
//                 },
//               },
//             },
//           }),
//         }
//       );

// const fcmResult = await fcmResp.json();
// console.log("📩 FCM Response for token", row.token, "=>", fcmResult);
//     }

// return new Response("Notifications sent", { status: 200 });
//   } catch (error) {
//   console.error("❌ Error in send-notification function:", error);
//   return new Response("Internal Server Error", { status: 500 });
// }
// });


// Supabase runtime types for Edge Functions
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "@supabase/supabase-js";
import { SignJWT, importPKCS8 } from "npm:jose";

// --- Supabase client
const supabaseUrl = Deno.env.get("PROJECT_URL")!;
const supabaseKey = Deno.env.get("SERVICE_ROLE_KEY")!;
const supabase = createClient(supabaseUrl, supabaseKey);

// --- Firebase service account (read from secrets)
const serviceAccount = {
  project_id: "dopashorts-2fdaf",
  private_key_id: Deno.env.get("FIREBASE_PRIVATE_KEY_ID")!,
  private_key: Deno.env.get("FIREBASE_PRIVATE_KEY")!,
  client_email: Deno.env.get("FIREBASE_CLIENT_EMAIL")!,
  client_id: Deno.env.get("FIREBASE_CLIENT_ID")!,
  token_uri: "https://oauth2.googleapis.com/token",
};

// --- Function to get Firebase OAuth2 access token
async function getAccessToken() {
  const now = Math.floor(Date.now() / 1000);

  const payload = {
    iss: serviceAccount.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: serviceAccount.token_uri,
    iat: now,
    exp: now + 3600,
  };

  // 🔑 Clean PEM key
  const pemKey = serviceAccount.private_key
    .replace(/\\n/g, "\n")
    .replace(/-----BEGIN PRIVATE KEY-----/, "-----BEGIN PRIVATE KEY-----\n")
    .replace(/-----END PRIVATE KEY-----/, "\n-----END PRIVATE KEY-----")
    .trim();

  const privateKey = await importPKCS8(pemKey, "RS256");

  const jwt = await new SignJWT(payload)
    .setProtectedHeader({ alg: "RS256", typ: "JWT" })
    .sign(privateKey);

  const resp = await fetch(serviceAccount.token_uri, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  const { access_token, error } = await resp.json();
  if (!access_token) {
    console.error("❌ Failed to fetch Firebase access token:", error);
    throw new Error("Failed to fetch Firebase access token");
  }
  return access_token;
}

// --- Main Edge Function handler
Deno.serve(async (req) => {
  try {
    const body = await req.json();
    const { event } = body;

    console.log("📨 New event received:", body);

    let actorId: string;
    let targetUserId: string;
    let title = "";
    let bodyText = "";

    // --- Handle Follow Event
    if (event === "follow") {
      const { follower_id, following_id } = body;
      actorId = String(follower_id).trim();
      targetUserId = String(following_id).trim();

      const { data: actorData } = await supabase
        .from("users")
        .select("username")
        .eq("id", actorId)
        .single();

      const actorName = actorData?.username || "Someone";

      title = "New Follower";
      bodyText = `${actorName} started following you`;

    // --- Handle Like Event
    } else if (event === "like") {
      const { user_id, video_id } = body;
      actorId = String(user_id).trim();

      // Find video owner
      const { data: videoData } = await supabase
        .from("videos")
        .select("user_id")
        .eq("id", String(video_id).trim())
        .single();

      if (!videoData) {
        return new Response("Video not found", { status: 404 });
      }
      targetUserId = videoData.user_id;

      const { data: actorData } = await supabase
        .from("users")
        .select("username")
        .eq("id", actorId)
        .single();

      const actorName = actorData?.username || "Someone";

      title = "New Like ❤️";
      bodyText = `${actorName} liked your video`;

    // --- Handle Comment Event
    } else if (event === "comment") {
      const { user_id, video_id, text } = body;
      actorId = String(user_id).trim();

      // Find video owner
      const { data: videoData } = await supabase
        .from("videos")
        .select("user_id")
        .eq("id", String(video_id).trim())
        .single();

      if (!videoData) {
        return new Response("Video not found", { status: 404 });
      }
      targetUserId = videoData.user_id;

      const { data: actorData } = await supabase
        .from("users")
        .select("username")
        .eq("id", actorId)
        .single();

      const actorName = actorData?.username || "Someone";

      title = "New Comment 💬";
      bodyText = `${actorName} commented: "${text}"`;

    } else {
      return new Response("Invalid event", { status: 400 });
    }

    // --- Get target user’s tokens
    const { data: tokensData, error: tokenError } = await supabase
      .from("user_tokens")
      .select("token")
      .eq("user_id", targetUserId);

    if (tokenError) {
      console.error("❌ Token query error:", tokenError);
      return new Response("Database error", { status: 500 });
    }

    if (!tokensData || tokensData.length === 0) {
      console.log("⚠️ No tokens found for user", targetUserId);
      return new Response("No tokens found", { status: 200 });
    }

    console.log("✅ Tokens found:", tokensData.map((t) => t.token));

    // --- Get Firebase access token
    const accessToken = await getAccessToken();

    // --- Send FCM notifications
    for (const row of tokensData) {
      const fcmResp = await fetch(
        `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`,
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${accessToken}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            message: {
              token: row.token,
              notification: {
                title,
                body: bodyText,
              },
              data: {
                event,
                actor_id: actorId,
              },
              android: {
                priority: "high",
                notification: {
                  channel_id: "high_importance_channel",
                  sound: "default",
                },
              },
              apns: {
                payload: {
                  aps: {
                    sound: "default",
                    contentAvailable: true,
                  },
                },
              },
            },
          }),
        }
      );

      const fcmResult = await fcmResp.json();
      console.log("📩 FCM Response for token", row.token, "=>", fcmResult);
    }

    return new Response("Notifications sent", { status: 200 });
  } catch (error) {
    console.error("❌ Error in send-notification function:", error);
    return new Response("Internal Server Error", { status: 500 });
  }
});
