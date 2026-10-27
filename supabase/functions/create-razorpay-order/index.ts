import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json",
};

function jsonResponse(
  data: Record<string, unknown>,
  status = 200,
) {
  return new Response(JSON.stringify(data), {
    status,
    headers: corsHeaders,
  });
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: corsHeaders,
    });
  }

  if (req.method !== "POST") {
    return jsonResponse(
      { error: "Method not allowed" },
      405,
    );
  }

  try {
    const body = await req.json();

    const { amount, currency, receipt, type, itemId } = body;

    // Flutter sends the amount in paise.
    // Do not multiply by 100 again.
    if (
      typeof amount !== "number" ||
      !Number.isSafeInteger(amount) ||
      amount <= 0
    ) {
      return jsonResponse(
        { error: "Invalid amount in paise" },
        400,
      );
    }

    if (
      typeof type !== "string" ||
      !["subject", "bundle"].includes(type) ||
      typeof itemId !== "string" ||
      itemId.trim().length === 0
    ) {
      return jsonResponse(
        { error: "Invalid purchase details" },
        400,
      );
    }

    if (currency != null && currency !== "INR") {
      return jsonResponse(
        { error: "Unsupported currency" },
        400,
      );
    }

    const keyId = Deno.env.get("RAZORPAY_KEY_ID");
    const keySecret = Deno.env.get("RAZORPAY_KEY_SECRET");

    if (!keyId || !keySecret) {
      console.error("Razorpay credentials are missing.");

      return jsonResponse(
        { error: "Payment service is not configured" },
        500,
      );
    }

    const orderPayload = {
      amount,
      currency: "INR",
      receipt:
        typeof receipt === "string" && receipt.length > 0
          ? receipt
          : `${type}_${itemId}_${Date.now()}`,
      notes: {
        type,
        itemId,
      },
    };

    const credentials = btoa(`${keyId}:${keySecret}`);

    const orderResponse = await fetch(
      "https://api.razorpay.com/v1/orders",
      {
        method: "POST",
        headers: {
          Authorization: `Basic ${credentials}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(orderPayload),
      },
    );

    const order = await orderResponse.json();

    if (!orderResponse.ok) {
      console.error(
        "Razorpay order creation failed:",
        order.error?.code ?? "UNKNOWN_ERROR",
      );

      return jsonResponse(
        { error: "Failed to create Razorpay order" },
        502,
      );
    }

    return jsonResponse({
      id: order.id,
      amount: order.amount,
      currency: order.currency,
      receipt: order.receipt,
    });
  } catch (error) {
    console.error(
      "Order creation error:",
      error instanceof Error ? error.message : "Unknown error",
    );

    return jsonResponse(
      { error: "Unable to create payment order" },
      500,
    );
  }
});
