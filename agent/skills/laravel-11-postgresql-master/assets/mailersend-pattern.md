```php
<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;
use MailerSend\Helpers\Builder\Personalization;
use MailerSend\LaravelDriver\MailerSendTrait;

class PremiumNotificationEmail extends Mailable
{
    use Queueable, SerializesModels, MailerSendTrait; // ✅ Uso obligatorio del Trait

    public function __construct(public array $data) {}

    /**
     * ✅ REGLA: Uso de Plantillas Premium de MailerSend.
     */
    public function build()
    {
        // Configurar Personalización (Variables {$key} en la plantilla)
        $personalization = [
            new Personalization($this->to[0]['address'], [
                'name'    => $this->data['name'],
                'url_cta' => $this->data['link'],
            ])
        ];

        return $this
            ->subject('Asunto del Correo Premium')
            ->mailersend(
                template_id: 'z3m5jgre260ldpyo', // ID de MailerSend
                personalization: $personalization,
                tags: ['notificacion', 'erp']
            );
    }
}
```