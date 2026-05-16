const fs = require('fs');
const path = require('path');

const skillsBase = '/Users/francoalvaradotello/QdoorAChile/qdoora-references/agent/skills';
const skills = [
    'erp-nomina-expert', 'security-iam-expert', 'prompt-architect-master',
    'erp-accounting-expert', 'erp-global-parameters-expert', 'erp-customs-expert',
    'erp-electronic-invoicing-expert', 'qa-data-auditor', 'technical-scribe-documentarian',
    'api-contract-aligner', 'ethical-hacking-auditor', 'committer',
    'bi-reporting-exports-master', 'angular-developer', 'lifecycle-tech-debt-guardian',
    'cloud-devops-engineer', 'qdoora-form-request-expert', 'mailersend-template-expert',
    'docker-compose-expert', 'skill-master'
];

skills.forEach(skill => {
    const evalDir = path.join(skillsBase, skill, 'evals');
    const evalFile = path.join(evalDir, 'evals.json');

    if (!fs.existsSync(evalDir)) {
        fs.mkdirSync(evalDir, { recursive: true });
    }

    if (!fs.existsSync(evalFile)) {
        const content = {
            skill_name: skill,
            evals: [
                {
                    id: 1,
                    prompt: `Ejecuta una tarea estándar usando la skill ${skill}.`,
                    expectations: [
                        `El resultado cumple con los estándares de ${skill}`,
                        "No hay errores de sintaxis",
                        "Se sigue el flujo de trabajo definido"
                    ]
                },
                {
                    id: 2,
                    prompt: `Caso de borde para ${skill}.`,
                    expectations: [
                        "El sistema maneja el error correctamente",
                        "Se proporciona feedback claro"
                    ]
                },
                {
                    id: 3,
                    prompt: `Validación de integridad para ${skill}.`,
                    expectations: [
                        "Los assets referenciados son accesibles",
                        "Se cumple con la seguridad multitenant"
                    ]
                }
            ]
        };
        fs.writeFileSync(evalFile, JSON.stringify(content, null, 2));
        console.log(`✅ Created evals for ${skill}`);
    }
});
