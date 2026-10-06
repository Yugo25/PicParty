// Push worker placeholder. Keep APNs/FCM credentials in Supabase secrets, never in Flutter.
Deno.serve(async (_req) => new Response(JSON.stringify({ok:true,service:'send-push'}),{headers:{'content-type':'application/json'}}));
