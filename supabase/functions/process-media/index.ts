// Server-side media worker placeholder for 1.0 beta deployment.
// Validate MIME, image dimensions/EXIF, video duration <= 5 minutes, then generate derivatives.
Deno.serve(async (_req) => new Response(JSON.stringify({ok:true,service:'process-media',status:'ready-for-worker'}),{headers:{'content-type':'application/json'}}));
