// Translation worker placeholder. Configure a provider with Supabase secrets before production use.
Deno.serve(async (_req) => new Response(JSON.stringify({ok:true,service:'translate-content'}),{headers:{'content-type':'application/json'}}));
