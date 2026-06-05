<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Qdoora — Sistema de Suscripciones Completo
 *
 * Tablas en orden de creación:
 *  1. module                   — catálogo de módulos del sistema
 *  2. plan                     — planes comerciales administrables
 *  3. plan_module              — qué módulos incluye cada plan
 *  4. quantity_tier            — rangos de cantidad (users / companies)
 *  5. plan_quantity_tier       — qué tiers están disponibles por plan
 *  6. subscriber               — suscriptores del sistema
 *  7. subscriber_plan          — plan activo e historial de planes del suscriptor
 *  8. subscriber_plan_module   — módulos activos del suscriptor (fuente de verdad de acceso)
 *  9. subscriber_quantity_addon— unidades adicionales provisionadas por support
 * 10. discount_code            — códigos de descuento y días de trial
 * 11. subscriber_plan_payment  — historial de pagos
 *
 * Decisiones de diseño:
 *  - plan.tier ('demo'|'basic'|'pro') separa identidad comercial del nombre de mercado.
 *  - quantity_tier.tier_level vincula rangos de cantidad al tier del plan.
 *  - plan_quantity_tier define explícitamente qué tiers puede elegir cada plan.
 *  - subscriber_plan nunca se borra: cambios de plan usan superseded_at + superseded_by.
 *  - subscriber_quantity_addon reemplaza extra_users/companies como columnas simples,
 *    dando historial completo de cada provisión con auditoría de support.
 *  - subscriber_plan_module registra origen ('plan'|'addon') y fechas de activación.
 *  - discount_code unifica codigo_promocional + lógica de trial days.
 *  - Límite efectivo = quantity_tier.max_qty + SUM(addons activos y vigentes).
 */
return new class extends Migration
{
    public function up(): void
    {
        // ─────────────────────────────────────────────────────────────────
        // 1. MODULE — catálogo administrable desde support portal
        // ─────────────────────────────────────────────────────────────────
        Schema::create('module', function (Blueprint $table) {
            $table->string('code')->primary();
            $table->string('name');
            $table->decimal('standalone_price', 24, 4)->default(0);
            $table->boolean('is_addon')->default(false);
            $table->boolean('active')->default(true);
            $table->text('description')->nullable();
            $table->timestampsTz();
        });

        DB::table('module')->insert([
            ['code' => 'CONTABILIDAD', 'name' => 'Contabilidad',       'standalone_price' => 0,     'is_addon' => false, 'active' => true,  'description' => 'Plan de cuentas, asientos, libro mayor, auxiliares'],
            ['code' => 'FACTURACION',  'name' => 'Factura Electrónica', 'standalone_price' => 15000, 'is_addon' => false, 'active' => false, 'description' => 'Emisión y recepción de documentos tributarios electrónicos SII'],
            ['code' => 'NOMINA',       'name' => 'Remuneraciones',      'standalone_price' => 10000, 'is_addon' => false, 'active' => false, 'description' => 'Empleados, liquidaciones, Previred'],
            ['code' => 'ADUANA',       'name' => 'Aduana',              'standalone_price' => 20000, 'is_addon' => false, 'active' => true,  'description' => 'DIN, DUS, libro circunstanciado'],
        ]);

        // ─────────────────────────────────────────────────────────────────
        // 2. PLAN — administrable; nunca se borra, se depreca
        //
        //    slug  → identificador estable en código (nunca cambia)
        //    name  → nombre de mercado (editable libremente)
        //    tier  → identidad comercial: demo | basic | pro
        //    deprecated_at → permite clientes legacy sin mostrar a nuevos
        // ─────────────────────────────────────────────────────────────────
        Schema::create('plan', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->string('slug')->unique();
            $table->string('name');
            $table->enum('tier', ['demo', 'basic', 'pro']);
            $table->enum('target', ['contador', 'empresa', 'all'])->default('all');
            $table->string('currency', 3)->default('CLP');
            $table->decimal('base_price', 24, 4)->default(0);
            $table->integer('base_user_quantity')->default(1);
            $table->integer('base_company_quantity')->nullable();
            $table->boolean('is_public')->default(true);
            $table->boolean('active')->default(true);
            $table->timestampTz('deprecated_at')->nullable();
            $table->text('notes')->nullable();
            $table->timestampsTz();
        });

        DB::table('plan')->insert([
            [
                'slug' => 'demo', 'name' => 'Demo', 'tier' => 'demo',
                'target' => 'all', 'base_price' => 0,
                'base_user_quantity' => 1, 'base_company_quantity' => 1,
                'is_public' => false, 'active' => true,
            ],
            [
                'slug' => 'contador-basic', 'name' => 'Plan Contador', 'tier' => 'basic',
                'target' => 'contador', 'base_price' => 25000,
                'base_user_quantity' => 5, 'base_company_quantity' => null,
                'is_public' => true, 'active' => true,
            ],
            [
                'slug' => 'empresa-pro', 'name' => 'Plan Empresa', 'tier' => 'pro',
                'target' => 'empresa', 'base_price' => 50000,
                'base_user_quantity' => 5, 'base_company_quantity' => 1,
                'is_public' => true, 'active' => true,
            ],
            [
                'slug' => 'aduana-pro', 'name' => 'Plan Aduana', 'tier' => 'pro',
                'target' => 'empresa', 'base_price' => 50000,
                'base_user_quantity' => 5, 'base_company_quantity' => 1,
                'is_public' => true, 'active' => true,
            ],
        ]);

        // ─────────────────────────────────────────────────────────────────
        // 3. PLAN_MODULE — módulos incluidos por plan
        //    included   = viene en el plan sin costo extra
        //    addon_price = precio si se agrega por separado
        // ─────────────────────────────────────────────────────────────────
        Schema::create('plan_module', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('plan_id');
            $table->foreign('plan_id')->references('id')->on('plan');
            $table->string('module_code');
            $table->foreign('module_code')->references('code')->on('module');
            $table->boolean('included')->default(true);
            $table->decimal('addon_price', 24, 4)->default(0);
            $table->unique(['plan_id', 'module_code']);
            $table->timestampsTz();
        });

        $planDemo     = DB::table('plan')->where('slug', 'demo')->value('id');
        $planContador = DB::table('plan')->where('slug', 'contador-basic')->value('id');
        $planEmpresa  = DB::table('plan')->where('slug', 'empresa-pro')->value('id');
        $planAduana   = DB::table('plan')->where('slug', 'aduana-pro')->value('id');

        DB::table('plan_module')->insert([
            ['plan_id' => $planDemo,     'module_code' => 'CONTABILIDAD', 'included' => true,  'addon_price' => 0],
            ['plan_id' => $planContador, 'module_code' => 'CONTABILIDAD', 'included' => true,  'addon_price' => 0],
            ['plan_id' => $planContador, 'module_code' => 'NOMINA',       'included' => false, 'addon_price' => 10000],
            ['plan_id' => $planEmpresa,  'module_code' => 'CONTABILIDAD', 'included' => true,  'addon_price' => 0],
            ['plan_id' => $planEmpresa,  'module_code' => 'NOMINA',       'included' => true,  'addon_price' => 0],
            ['plan_id' => $planEmpresa,  'module_code' => 'FACTURACION',  'included' => false, 'addon_price' => 15000],
            ['plan_id' => $planAduana,   'module_code' => 'ADUANA',       'included' => true,  'addon_price' => 0],
            ['plan_id' => $planAduana,   'module_code' => 'CONTABILIDAD', 'included' => false, 'addon_price' => 12000],
        ]);

        // ─────────────────────────────────────────────────────────────────
        // 4. QUANTITY_TIER — rangos de cantidad administrables
        //
        //    dimension  = 'users' | 'companies'
        //    tier_level = 'demo' | 'basic' | 'pro'
        //                 Conecta el tier de cantidad con el tier del plan.
        //                 Un plan demo solo puede usar tiers con tier_level='demo'.
        //                 Validación en capa de servicio (no FK).
        //    max_qty = 9999 → sin límite práctico
        // ─────────────────────────────────────────────────────────────────
        Schema::create('quantity_tier', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->enum('dimension', ['users', 'companies']);
            $table->enum('tier_level', ['demo', 'basic', 'pro'])->default('basic');
            $table->string('code')->unique();
            $table->string('name');
            $table->integer('min_qty');
            $table->integer('max_qty');
            $table->decimal('unit_price', 24, 4)->default(0);
            $table->boolean('active')->default(true);
            $table->timestampsTz();
        });

        DB::table('quantity_tier')->insert([
            // Users
            ['dimension' => 'users', 'tier_level' => 'demo',  'code' => 'users-demo',       'name' => 'Demo',        'min_qty' => 1,  'max_qty' => 1,    'unit_price' => 0],
            ['dimension' => 'users', 'tier_level' => 'basic', 'code' => 'users-basico',      'name' => 'Básico',      'min_qty' => 1,  'max_qty' => 5,    'unit_price' => 0],
            ['dimension' => 'users', 'tier_level' => 'pro',   'code' => 'users-intermedio',  'name' => 'Intermedio',  'min_qty' => 6,  'max_qty' => 8,    'unit_price' => 15000],
            ['dimension' => 'users', 'tier_level' => 'pro',   'code' => 'users-full',        'name' => 'Full',        'min_qty' => 9,  'max_qty' => 12,   'unit_price' => 20000],
            ['dimension' => 'users', 'tier_level' => 'pro',   'code' => 'users-enterprise',  'name' => 'Enterprise',  'min_qty' => 13, 'max_qty' => 9999, 'unit_price' => 18000],
            // Companies
            ['dimension' => 'companies', 'tier_level' => 'demo',  'code' => 'companies-demo',     'name' => 'Demo',     'min_qty' => 1, 'max_qty' => 1,    'unit_price' => 0],
            ['dimension' => 'companies', 'tier_level' => 'basic', 'code' => 'companies-inicia',   'name' => 'Inicia',   'min_qty' => 1, 'max_qty' => 1,    'unit_price' => 0],
            ['dimension' => 'companies', 'tier_level' => 'pro',   'code' => 'companies-medio',    'name' => 'Medio',    'min_qty' => 2, 'max_qty' => 3,    'unit_price' => 15000],
            ['dimension' => 'companies', 'tier_level' => 'pro',   'code' => 'companies-avanzado', 'name' => 'Avanzado', 'min_qty' => 4, 'max_qty' => 5,    'unit_price' => 20000],
            ['dimension' => 'companies', 'tier_level' => 'pro',   'code' => 'companies-ilimit',   'name' => 'Ilimitado','min_qty' => 6, 'max_qty' => 9999, 'unit_price' => 17000],
        ]);

        // ─────────────────────────────────────────────────────────────────
        // 5. PLAN_QUANTITY_TIER — tiers disponibles por plan
        //
        //    Define qué opciones de cantidad puede elegir el cliente al
        //    contratar. Support edita esto sin deploy.
        //    is_default = true → se asigna automáticamente si el cliente
        //    no elige explícitamente. Un solo default por (plan, dimension).
        // ─────────────────────────────────────────────────────────────────
        Schema::create('plan_quantity_tier', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('plan_id');
            $table->foreign('plan_id')->references('id')->on('plan')->onDelete('cascade');
            $table->unsignedBigInteger('quantity_tier_id');
            $table->foreign('quantity_tier_id')->references('id')->on('quantity_tier');
            $table->boolean('is_default')->default(false);
            $table->unique(['plan_id', 'quantity_tier_id'], 'uq_plan_qty_tier');
            $table->timestampsTz();
        });

        $tUserDemo       = DB::table('quantity_tier')->where('code', 'users-demo')->value('id');
        $tUserBasico     = DB::table('quantity_tier')->where('code', 'users-basico')->value('id');
        $tUserIntermedio = DB::table('quantity_tier')->where('code', 'users-intermedio')->value('id');
        $tUserFull       = DB::table('quantity_tier')->where('code', 'users-full')->value('id');
        $tUserEnterprise = DB::table('quantity_tier')->where('code', 'users-enterprise')->value('id');
        $tCoDemo         = DB::table('quantity_tier')->where('code', 'companies-demo')->value('id');
        $tCoInicia       = DB::table('quantity_tier')->where('code', 'companies-inicia')->value('id');
        $tCoMedio        = DB::table('quantity_tier')->where('code', 'companies-medio')->value('id');
        $tCoAvanzado     = DB::table('quantity_tier')->where('code', 'companies-avanzado')->value('id');
        $tCoIlimit       = DB::table('quantity_tier')->where('code', 'companies-ilimit')->value('id');

        DB::table('plan_quantity_tier')->insert([
            // Demo → solo tier demo, forzado
            ['plan_id' => $planDemo,     'quantity_tier_id' => $tUserDemo,       'is_default' => true],
            ['plan_id' => $planDemo,     'quantity_tier_id' => $tCoDemo,         'is_default' => true],
            // Contador → usuarios basic y pro; sin límite de empresas (no se registra company tier)
            ['plan_id' => $planContador, 'quantity_tier_id' => $tUserBasico,     'is_default' => true],
            ['plan_id' => $planContador, 'quantity_tier_id' => $tUserIntermedio, 'is_default' => false],
            ['plan_id' => $planContador, 'quantity_tier_id' => $tUserFull,       'is_default' => false],
            ['plan_id' => $planContador, 'quantity_tier_id' => $tUserEnterprise, 'is_default' => false],
            // Empresa Pro → usuarios y empresas
            ['plan_id' => $planEmpresa,  'quantity_tier_id' => $tUserBasico,     'is_default' => true],
            ['plan_id' => $planEmpresa,  'quantity_tier_id' => $tUserIntermedio, 'is_default' => false],
            ['plan_id' => $planEmpresa,  'quantity_tier_id' => $tUserFull,       'is_default' => false],
            ['plan_id' => $planEmpresa,  'quantity_tier_id' => $tUserEnterprise, 'is_default' => false],
            ['plan_id' => $planEmpresa,  'quantity_tier_id' => $tCoInicia,       'is_default' => true],
            ['plan_id' => $planEmpresa,  'quantity_tier_id' => $tCoMedio,        'is_default' => false],
            ['plan_id' => $planEmpresa,  'quantity_tier_id' => $tCoAvanzado,     'is_default' => false],
            ['plan_id' => $planEmpresa,  'quantity_tier_id' => $tCoIlimit,       'is_default' => false],
            // Aduana Pro
            ['plan_id' => $planAduana,   'quantity_tier_id' => $tUserBasico,     'is_default' => true],
            ['plan_id' => $planAduana,   'quantity_tier_id' => $tUserIntermedio, 'is_default' => false],
            ['plan_id' => $planAduana,   'quantity_tier_id' => $tUserFull,       'is_default' => false],
            ['plan_id' => $planAduana,   'quantity_tier_id' => $tCoInicia,       'is_default' => true],
            ['plan_id' => $planAduana,   'quantity_tier_id' => $tCoMedio,        'is_default' => false],
            ['plan_id' => $planAduana,   'quantity_tier_id' => $tCoAvanzado,     'is_default' => false],
        ]);

        // ─────────────────────────────────────────────────────────────────
        // 6. SUBSCRIBER
        // ─────────────────────────────────────────────────────────────────
        Schema::create('subscriber', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('user_id');
            $table->foreign('user_id')->references('id')->on('users');
            $table->boolean('is_demo')->default(true);
            $table->timestampTz('subscribed_at')->nullable();
            $table->timestampTz('valid_to')->nullable();
            $table->timestampTz('unsubscribed_at')->nullable();
            $table->timestampsTz();
        });

        // ─────────────────────────────────────────────────────────────────
        // 7. SUBSCRIBER_PLAN — snapshot inmutable con historial completo
        //
        //    NUNCA se borra un registro. Cambio de plan:
        //      1. Crear nuevo subscriber_plan con starts_at = hoy
        //      2. Setear superseded_at + superseded_by en el anterior
        //    Esto garantiza que planes "obsoletos" de clientes legacy
        //    sean siempre consultables con sus condiciones originales.
        //
        //    Límite efectivo (calculado en SubscriptionLimitService):
        //      quantity_tier.max_qty + SUM(subscriber_quantity_addon activos)
        // ─────────────────────────────────────────────────────────────────
        Schema::create('subscriber_plan', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('subscriber_id');
            $table->foreign('subscriber_id')->references('id')->on('subscriber');
            $table->unsignedBigInteger('plan_id');
            $table->foreign('plan_id')->references('id')->on('plan');
            $table->string('plan_name_snapshot'); // nombre del plan al contratar (aunque se deprece)
            $table->unsignedBigInteger('user_tier_id');
            $table->foreign('user_tier_id')->references('id')->on('quantity_tier');
            $table->unsignedBigInteger('company_tier_id')->nullable();
            $table->foreign('company_tier_id')->references('id')->on('quantity_tier');
            $table->enum('status', [
                'trialing',   // en periodo demo
                'active',     // pagando y vigente
                'past_due',   // pago fallido, aún accesible con gracia
                'suspended',  // acceso bloqueado por deuda
                'cancelled',  // baja voluntaria
                'superseded', // reemplazado por un nuevo plan (historial)
            ])->default('trialing');
            $table->timestampTz('starts_at')->nullable();
            $table->timestampTz('ends_at')->nullable();
            $table->timestampTz('superseded_at')->nullable();
            $table->unsignedBigInteger('superseded_by')->nullable();
            $table->foreign('superseded_by')->references('id')->on('subscriber_plan');
            $table->text('internal_notes')->nullable();
            $table->timestampsTz();
        });

        // ─────────────────────────────────────────────────────────────────
        // 8. SUBSCRIBER_PLAN_MODULE — fuente de verdad para middleware de acceso
        //
        //    origin = 'plan'  → viene incluido en el plan
        //    origin = 'addon' → contratado por separado después
        //    deactivated_at   → soft-delete para auditoría; null = activo
        // ─────────────────────────────────────────────────────────────────
        Schema::create('subscriber_plan_module', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('subscriber_plan_id');
            $table->foreign('subscriber_plan_id')->references('id')->on('subscriber_plan');
            $table->string('module_code');
            $table->foreign('module_code')->references('code')->on('module');
            $table->enum('origin', ['plan', 'addon'])->default('plan');
            $table->timestampTz('activated_at')->nullable();
            $table->timestampTz('deactivated_at')->nullable();
            $table->unique(['subscriber_plan_id', 'module_code']);
            $table->timestampsTz();
        });

        // ─────────────────────────────────────────────────────────────────
        // 9. SUBSCRIBER_QUANTITY_ADDON — unidades adicionales por support
        //
        //    Reemplaza extra_users/extra_companies como columnas simples.
        //    Cada fila = una provisión puntual con auditoría completa.
        //    Nunca se borra; si se revoca se setea revoked_at.
        //
        //    Activo y vigente =
        //      valid_from <= NOW()
        //      AND (valid_until IS NULL OR valid_until > NOW())
        //      AND revoked_at IS NULL
        //
        //    Índice idx_addon_lookup optimiza la consulta de límite
        //    efectivo, que se ejecuta en cada acción del usuario.
        // ─────────────────────────────────────────────────────────────────
        Schema::create('subscriber_quantity_addon', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('subscriber_plan_id');
            $table->foreign('subscriber_plan_id')->references('id')->on('subscriber_plan')->onDelete('cascade');
            $table->enum('dimension', ['users', 'companies']);
            $table->unsignedInteger('quantity');
            $table->decimal('unit_price', 24, 4)->default(0);
            $table->decimal('total_price', 24, 4)->default(0);
            $table->string('reason')->nullable();
            $table->string('granted_by');
            $table->timestampTz('valid_from');
            $table->timestampTz('valid_until')->nullable();
            $table->timestampTz('revoked_at')->nullable();
            $table->string('revoked_by')->nullable();
            $table->string('revoked_reason')->nullable();
            $table->timestampsTz();
            $table->index(['subscriber_plan_id', 'dimension', 'revoked_at'], 'idx_addon_lookup');
        });

        // ─────────────────────────────────────────────────────────────────
        // 10. DISCOUNT_CODE — unifica codigo_promocional + trial days
        //
        //    type = 'fixed'      → descuento en monto fijo (CLP)
        //    type = 'percent'    → descuento en porcentaje (1-100)
        //    type = 'trial_days' → días adicionales de prueba
        //    max_uses = null     → usos ilimitados
        // ─────────────────────────────────────────────────────────────────
        Schema::create('discount_code', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->string('code')->unique();
            $table->enum('type', ['fixed', 'percent', 'trial_days']);
            $table->decimal('value', 24, 4)->nullable();
            $table->integer('additional_trial_days')->nullable();
            $table->integer('max_uses')->nullable();
            $table->integer('used_count')->default(0);
            $table->boolean('active')->default(true);
            $table->timestampTz('expires_at')->nullable();
            $table->timestampsTz();
        });

        // ─────────────────────────────────────────────────────────────────
        // 11. SUBSCRIBER_PLAN_PAYMENT — historial inmutable de pagos
        //
        //    gateway = 'payu' | 'transbank' | 'stripe' | 'manual' | 'free'
        //    Un pago nunca se borra; si se revierte se crea uno de tipo refunded.
        // ─────────────────────────────────────────────────────────────────
        Schema::create('subscriber_plan_payment', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('subscriber_id');
            $table->foreign('subscriber_id')->references('id')->on('subscriber');
            $table->unsignedBigInteger('subscriber_plan_id');
            $table->foreign('subscriber_plan_id')->references('id')->on('subscriber_plan');
            $table->unsignedBigInteger('discount_code_id')->nullable();
            $table->foreign('discount_code_id')->references('id')->on('discount_code');
            $table->decimal('subtotal', 24, 4)->default(0);
            $table->decimal('discount_amount', 24, 4)->default(0);
            $table->decimal('total', 24, 4)->default(0);
            $table->integer('months_paid')->unsigned()->default(1);
            $table->string('gateway')->default('manual');
            $table->string('gateway_ref')->nullable();
            $table->string('gateway_signature')->nullable();
            $table->enum('status', ['pending', 'paid', 'failed', 'refunded'])->default('pending');
            $table->string('email_buyer')->nullable();
            $table->timestampTz('paid_at')->nullable();
            $table->timestampsTz();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('subscriber_plan_payment');
        Schema::dropIfExists('discount_code');
        Schema::dropIfExists('subscriber_quantity_addon');
        Schema::dropIfExists('subscriber_plan_module');
        Schema::dropIfExists('subscriber_plan');
        Schema::dropIfExists('subscriber');
        Schema::dropIfExists('plan_quantity_tier');
        Schema::dropIfExists('quantity_tier');
        Schema::dropIfExists('plan_module');
        Schema::dropIfExists('plan');
        Schema::dropIfExists('module');
    }
};