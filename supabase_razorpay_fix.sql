-- Add payment tracking columns to the purchases table
ALTER TABLE public.purchases 
ADD COLUMN IF NOT EXISTS payment_id text,
ADD COLUMN IF NOT EXISTS amount integer,
ADD COLUMN IF NOT EXISTS expires_at timestamp with time zone;

-- Optional: Update existing records to reflect a 30-day expiry if they don't have one
UPDATE public.purchases 
SET expires_at = purchased_at + interval '30 days'
WHERE expires_at IS NULL;
