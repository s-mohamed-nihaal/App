import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // 1. Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // 2. Add auth log for debugging (bypass JWT verification issue by just reading header)
    const authHeader = req.headers.get('Authorization')
    console.log("Auth header present:", !!authHeader)

    // 3. Parse request body
    const { amount, currency, receipt } = await req.json()

    if (!amount) {
      throw new Error("Amount is required")
    }

    // 4. Get Razorpay credentials from environment variables
    const KEY_ID = Deno.env.get('RAZORPAY_KEY_ID')
    const KEY_SECRET = Deno.env.get('RAZORPAY_KEY_SECRET')

    if (!KEY_ID || !KEY_SECRET) {
      console.error("RAZORPAY_KEY_ID or RAZORPAY_KEY_SECRET is missing in Edge Function secrets")
      return new Response(
        JSON.stringify({ error: 'Razorpay keys are not configured in Supabase' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // 5. Create basic auth token
    const credentials = btoa(`${KEY_ID}:${KEY_SECRET}`)

    console.log(`Creating order for ${amount} ${currency || 'INR'}...`)

    // 6. Call Razorpay API
    const response = await fetch('https://api.razorpay.com/v1/orders', {
      method: 'POST',
      headers: {
        'Authorization': `Basic ${credentials}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        amount: amount, // already in paise from frontend
        currency: currency || 'INR',
        receipt: receipt || `receipt_${Date.now()}`,
      }),
    })

    const data = await response.json()

    if (!response.ok) {
      console.error("Razorpay API Error:", data)
      return new Response(
        JSON.stringify({ error: data.error?.description || 'Failed to create Razorpay order' }),
        { status: response.status, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    console.log("Order created successfully:", data.id)

    // 7. Return the order data
    return new Response(
      JSON.stringify({ id: data.id, amount: data.amount, currency: data.currency }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error("Function Error:", error.message)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
