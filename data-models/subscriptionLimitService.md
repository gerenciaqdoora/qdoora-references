<?php

namespace App\Services\Subscription;

use App\Models\SubscriberPlan;
use App\Models\SubscriberQuantityAddon;
use App\Models\PlanQuantityTier;
use App\Models\QuantityTier;
use Illuminate\Support\Carbon;

/**
 * SubscriptionLimitService
 *
 * Fuente de verdad para preguntar cuántos usuarios/empresas
 * tiene disponibles un suscriptor en un momento dado.
 *
 * Uso típico:
 *   $service = app(SubscriptionLimitService::class);
 *
 *   // ¿Puede crear un usuario más?
 *   $service->canAdd($subscriberPlan, 'users');
 *
 *   // ¿Cuántos le quedan disponibles?
 *   $service->remaining($subscriberPlan, 'users');
 *
 *   // Límite total actual
 *   $service->effectiveLimit($subscriberPlan, 'users');
 *
 *   // Tiers disponibles para este plan (para mostrar en UI de upgrade)
 *   $service->availableTiers($subscriberPlan->plan_id, 'users');
 *
 *   // Validar que el tier elegido es compatible con el plan
 *   $service->tierIsAllowed($subscriberPlan->plan_id, $tierId);
 */
class SubscriptionLimitService
{
    /**
     * Límite efectivo de una dimensión para un subscriber_plan activo.
     *
     * efectivo = tier.max_qty + SUM(addons activos y vigentes)
     *
     * Si el tier no tiene límite (max_qty = 9999), se devuelve INF
     * para que las comparaciones de "puede agregar" siempre sean true.
     */
    public function effectiveLimit(SubscriberPlan $plan, string $dimension): int|float
    {
        $tier = $this->resolveTier($plan, $dimension);

        if (! $tier) {
            // Sin tier configurado → sin límite (aplica a contadores sin company_tier)
            return INF;
        }

        // 9999 se usa como "sin límite práctico" en los seeds
        $base = $tier->max_qty >= 9999 ? INF : $tier->max_qty;

        if ($base === INF) {
            return INF;
        }

        $addons = $this->activeAddonsSum($plan->id, $dimension);

        return $base + $addons;
    }

    /**
     * Cuántas unidades están actualmente en uso.
     * Delega al modelo correspondiente; aquí se ejemplifica con users.
     */
    public function currentUsage(SubscriberPlan $plan, string $dimension): int
    {
        return match ($dimension) {
            'users'     => $plan->subscriber->users()->count(),
            'companies' => $plan->subscriber->companies()->count(),
            default     => throw new \InvalidArgumentException("Dimensión desconocida: {$dimension}"),
        };
    }

    /**
     * ¿Puede agregar N unidades más?
     */
    public function canAdd(SubscriberPlan $plan, string $dimension, int $quantity = 1): bool
    {
        $limit = $this->effectiveLimit($plan, $dimension);

        if ($limit === INF) {
            return true;
        }

        return ($this->currentUsage($plan, $dimension) + $quantity) <= $limit;
    }

    /**
     * Unidades disponibles restantes. Devuelve INF si sin límite.
     */
    public function remaining(SubscriberPlan $plan, string $dimension): int|float
    {
        $limit = $this->effectiveLimit($plan, $dimension);

        if ($limit === INF) {
            return INF;
        }

        return max(0, $limit - $this->currentUsage($plan, $dimension));
    }

    /**
     * Tiers disponibles para un plan y dimensión dados.
     * Usado en la UI de contratación/upgrade para mostrar solo las opciones válidas.
     */
    public function availableTiers(int $planId, string $dimension): \Illuminate\Support\Collection
    {
        return QuantityTier::query()
            ->join('plan_quantity_tier as pqt', 'pqt.quantity_tier_id', '=', 'quantity_tier.id')
            ->where('pqt.plan_id', $planId)
            ->where('quantity_tier.dimension', $dimension)
            ->where('quantity_tier.active', true)
            ->orderBy('quantity_tier.min_qty')
            ->select('quantity_tier.*', 'pqt.is_default')
            ->get();
    }

    /**
     * Verifica que un tier específico está permitido para un plan.
     * Usar antes de asignar user_tier_id o company_tier_id en subscriber_plan.
     */
    public function tierIsAllowed(int $planId, int $tierId): bool
    {
        return PlanQuantityTier::where('plan_id', $planId)
            ->where('quantity_tier_id', $tierId)
            ->exists();
    }

    /**
     * Tier default para un plan y dimensión.
     * Se usa al crear subscriber_plan si el cliente no eligió explícitamente.
     */
    public function defaultTier(int $planId, string $dimension): ?QuantityTier
    {
        return QuantityTier::query()
            ->join('plan_quantity_tier as pqt', 'pqt.quantity_tier_id', '=', 'quantity_tier.id')
            ->where('pqt.plan_id', $planId)
            ->where('pqt.is_default', true)
            ->where('quantity_tier.dimension', $dimension)
            ->select('quantity_tier.*')
            ->first();
    }

    /**
     * Otorga un addon de unidades adicionales (acción de support).
     *
     * Ejemplo:
     *   $service->grantAddon(
     *       plan: $subscriberPlan,
     *       dimension: 'users',
     *       quantity: 2,
     *       grantedBy: 'soporte@qdoora.com',
     *       reason: 'Cliente solicitó 2 usuarios extra para proyecto puntual',
     *       validUntil: now()->addMonths(3),
     *   );
     */
    public function grantAddon(
        SubscriberPlan $plan,
        string $dimension,
        int $quantity,
        string $grantedBy,
        string $reason = '',
        ?Carbon $validFrom = null,
        ?Carbon $validUntil = null,
    ): SubscriberQuantityAddon {
        $tier      = $this->resolveTier($plan, $dimension);
        $unitPrice = $tier?->unit_price ?? 0;

        return SubscriberQuantityAddon::create([
            'subscriber_plan_id' => $plan->id,
            'dimension'          => $dimension,
            'quantity'           => $quantity,
            'unit_price'         => $unitPrice,
            'total_price'        => $unitPrice * $quantity,
            'reason'             => $reason,
            'granted_by'         => $grantedBy,
            'valid_from'         => $validFrom ?? now(),
            'valid_until'        => $validUntil,
        ]);
    }

    /**
     * Revoca un addon activo. No borra, solo sella con timestamp.
     */
    public function revokeAddon(
        SubscriberQuantityAddon $addon,
        string $revokedBy,
        string $reason = '',
    ): void {
        $addon->update([
            'revoked_at'     => now(),
            'revoked_by'     => $revokedBy,
            'revoked_reason' => $reason,
        ]);
    }

    // ─────────────────────────────────────────────────────────────────────
    // Privados
    // ─────────────────────────────────────────────────────────────────────

    private function resolveTier(SubscriberPlan $plan, string $dimension): ?QuantityTier
    {
        return match ($dimension) {
            'users'     => $plan->userTier,
            'companies' => $plan->companyTier,
            default     => throw new \InvalidArgumentException("Dimensión desconocida: {$dimension}"),
        };
    }

    private function activeAddonsSum(int $subscriberPlanId, string $dimension): int
    {
        return (int) SubscriberQuantityAddon::where('subscriber_plan_id', $subscriberPlanId)
            ->where('dimension', $dimension)
            ->where('valid_from', '<=', now())
            ->where(fn ($q) => $q->whereNull('valid_until')->orWhere('valid_until', '>', now()))
            ->whereNull('revoked_at')
            ->sum('quantity');
    }
}