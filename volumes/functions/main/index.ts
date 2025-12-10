// Main entrypoint for Edge Functions
// This is required for the Edge Functions runtime to start

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

console.log("Edge Functions main worker started")

serve(async (req) => {
  const { pathname } = new URL(req.url)
  
  console.log(`Request: ${req.method} ${pathname}`)
  
  // Health check endpoint
  if (pathname === "/health" || pathname === "/" || pathname === "") {
    return new Response(
      JSON.stringify({ 
        status: "ok", 
        message: "Supabase Edge Functions runtime is running",
        timestamp: new Date().toISOString(),
        version: "1.0.0"
      }),
      { 
        headers: { "Content-Type": "application/json" },
        status: 200 
      }
    )
  }
  
  // Function not found
  return new Response(
    JSON.stringify({ 
      error: "Function not found",
      path: pathname,
      message: "Create your functions in volumes/functions/<function-name>/index.ts"
    }),
    { 
      headers: { "Content-Type": "application/json" },
      status: 404 
    }
  )
})