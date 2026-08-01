import fs from 'fs';
import path from 'path';
import { supabaseAdmin } from '../config/supabase';
import { env } from '../config/env';

async function runMigration() {
  console.log('==============================================');
  console.log('Proofly Supabase Database Migration & Health');
  console.log('==============================================');
  console.log(`Supabase Project URL: ${env.SUPABASE_URL}`);

  try {
    const possiblePaths = [
      path.resolve(process.cwd(), 'infrastructure/database/schema.sql'),
      path.resolve(__dirname, '../../../../infrastructure/database/schema.sql'),
      path.resolve(__dirname, '../../../infrastructure/database/schema.sql'),
    ];
    const schemaPath = possiblePaths.find((p) => fs.existsSync(p));
    if (!schemaPath) {
      throw new Error(`Schema file not found in candidates: ${possiblePaths.join(', ')}`);
    }

    const sqlContent = fs.readFileSync(schemaPath, 'utf8');
    console.log(`Read SQL schema (${sqlContent.length} bytes)`);

    // Test connectivity by querying users or checking Supabase connection
    const { data: users, error: testError } = await supabaseAdmin.from('users').select('count', { count: 'exact', head: true });
    
    if (testError && testError.code === 'PGRST205') {
      console.log('ℹ️ Tables not yet created in Supabase database.');
      console.log('To apply the schema:');
      console.log('1. Go to your Supabase Dashboard: https://supabase.com/dashboard/project/hhqvlubkzmitkjuoaxrz/sql');
      console.log('2. Copy and paste the contents of infrastructure/database/schema.sql into the SQL Editor and click Run.');
    } else if (testError) {
      console.log('ℹ️ Supabase response:', testError.message);
    } else {
      console.log('✅ Connected to Supabase! Database tables are present.');
    }

  } catch (error: any) {
    console.error('❌ Migration check failed:', error.message);
  }
}

if (require.main === module) {
  runMigration();
}

export { runMigration };
