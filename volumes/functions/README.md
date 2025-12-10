# Supabase Edge Functions

This directory contains Supabase Edge Functions powered by Deno.

## Structure

```
functions/
├── main/                 # Main entrypoint (required)
│   └── index.ts
├── hello-world/          # Example function
│   └── index.ts
└── README.md             # This file
```

**Important**: The `main` directory is required by the Edge Functions runtime as the primary entrypoint.

## Creating a New Function

1. Create a new directory for your function:
```bash
mkdir -p volumes/functions/my-function
```

2. Create an `index.ts` file in your function directory:
```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

serve(async (req) => {
  const { name } = await req.json()

  return new Response(
    JSON.stringify({ message: `Hello ${name}!` }),
    { headers: { "Content-Type": "application/json" } }
  )
})
```

3. Deploy by restarting the functions service:
```bash
docker compose restart functions
```

4. Access your function at:
```
http://localhost:8000/functions/v1/my-function
```

## Environment Variables

Functions have access to these environment variables:

- `SUPABASE_URL` - Your Supabase URL
- `SUPABASE_ANON_KEY` - Anonymous key
- `SUPABASE_SERVICE_ROLE_KEY` - Service role key (use carefully!)
- `JWT_SECRET` - JWT secret for verification

## Using Supabase Client

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

serve(async (req) => {
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_ANON_KEY") ?? ""
  )

  const { data, error } = await supabase
    .from("your_table")
    .select("*")

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { "Content-Type": "application/json" }
    })
  }

  return new Response(JSON.stringify({ data }), {
    headers: { "Content-Type": "application/json" }
  })
})
```

## CORS Support

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders })
  }

  // Your function logic
  const data = { message: "Hello World" }

  return new Response(JSON.stringify(data), {
    headers: { ...corsHeaders, "Content-Type": "application/json" }
  })
})
```

## Testing Functions Locally

Test your function with curl:

```bash
curl -X POST http://localhost:8000/functions/v1/my-function \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"name":"World"}'
```

## Resources

- [Deno Documentation](https://deno.land/manual)
- [Supabase Functions Guide](https://supabase.com/docs/guides/functions)
- [Edge Functions Examples](https://github.com/supabase/supabase/tree/master/examples/edge-functions)
