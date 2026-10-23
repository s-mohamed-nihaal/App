import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const body = await req.json()
    const { amount, currency, receipt, type, itemId } = body

    const keyId = Deno.env.get('RAZORPAY_KEY_ID')
    const keySecret = Deno.env.get('RAZORPAY_KEY_SECRET')

    if (!keyId || !keySecret) {
      throw new Error('Razorpay credentials missing in Supabase secrets')
    }

    const credentials = btoa(`${keyId}:${keySecret}`)

    const orderPayload = {
      amount: Math.round(amount * 100), // convert to paise
      currency: currency || 'INR',
      receipt: receipt || `${type}_${itemId}_${Date.now()}`,
      notes: { type, itemId }
    }

    const orderResponse = await fetch('https://api.razorpay.com/v1/orders', {
      method: 'POST',
      headers: {
        'Authorization': `Basic ${credentials}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(orderPayload),
    })

    const order = await orderResponse.json()

    if (!orderResponse.ok) {
      console.error('Razorpay Error Payload:', order)
      throw new Error(order.error?.description || 'Failed to create Razorpay order')
    }

    return new Response(JSON.stringify(order), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })

  } catch (error) {
    console.error('Edge function error:', error.message)
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
    )
  }
})
