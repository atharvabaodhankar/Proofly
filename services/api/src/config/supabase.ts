import { createClient } from '@supabase/supabase-js';
import { env } from './env';

// Supabase Admin Client using the Service Role Key (full database access for backend services)
export const supabaseAdmin = createClient(env.SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY, {
  auth: {
    persistSession: false,
    autoRefreshToken: false,
  },
});

// Supabase Anon Client for public / user-scoped requests
export const supabaseClient = createClient(env.SUPABASE_URL, env.SUPABASE_ANON_KEY, {
  auth: {
    persistSession: false,
  },
});
