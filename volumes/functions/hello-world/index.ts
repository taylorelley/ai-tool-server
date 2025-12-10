// Example Edge Function - Hello World
// Access at: http://localhost:8000/functions/v1/hello-world

import { serve } from "https://deno.land/std@release-2025.11.17/http/server.ts"

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
}

console.log("Hello World function started")

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === "OPTIONS") {
    return new Response(null, {
      headers: corsHeaders
    })
  }

  try {
    const { name = "World" } = await req.json().catch(() => ({}))

    const response = {
      message: `Hello ${name}!`,
      timestamp: new Date().toISOString(),
      method: req.method,
      url: req.url
    }

    return new Response(
      JSON.stringify(response, null, 2),
      {
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json"
        },
        status: 200
      }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({
        error: error.message
      }),
      {
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json"
        },
        status: 500
      }
    )
  }
})
