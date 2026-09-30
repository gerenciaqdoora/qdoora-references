const fs = require('fs');
const path = require('path');

function validateSkill() {
    const args = process.argv.slice(2);
    const pathArg = args.find(arg => arg.startsWith('--path='));
    const skillPath = pathArg ? pathArg.split('=')[1] : null;

    if (!skillPath || !fs.existsSync(skillPath)) {
        console.error('❌ Error: Debes proporcionar una ruta válida con --path=/ruta/a/la/skill');
        process.exit(1);
    }

    const skillMdPath = path.join(skillPath, 'SKILL.md');
    if (!fs.existsSync(skillMdPath)) {
        console.error(`❌ Error: No se encontró SKILL.md en ${skillPath}`);
        process.exit(1);
    }

    const content = fs.readFileSync(skillMdPath, 'utf-8');
    const frontmatterMatch = content.match(/^---\s*([\s\S]*?)\s*---/);

    if (!frontmatterMatch) {
        console.error('❌ Error: SKILL.md no tiene un bloque de frontmatter válido.');
        process.exit(1);
    }

    const frontmatter = frontmatterMatch[1];
    const hasName = frontmatter.includes('name:');
    const hasDescription = frontmatter.includes('description:');

    if (!hasName || !hasDescription) {
        console.error('❌ Error: El frontmatter debe contener "name" y "description".');
        process.exit(1);
    }

    let errors = 0;

    const skillName = frontmatter.match(/name:\s*(.*)/)?.[1]?.trim();
    const folderName = path.basename(skillPath);

    if (skillName !== folderName) {
        console.warn(`⚠️ Advertencia: El nombre de la skill en el frontmatter ("${skillName}") no coincide con el nombre de la carpeta ("${folderName}").`);
    }

    // Validar evals/evals.json
    const evalsPath = path.join(skillPath, 'evals/evals.json');
    if (!fs.existsSync(evalsPath)) {
        console.error('❌ Error: El archivo evals/evals.json es OBLIGATORIO.');
        errors++;
    } else {
        try {
            const evalsJson = JSON.parse(fs.readFileSync(evalsPath, 'utf-8'));
            if (!evalsJson.evals || evalsJson.evals.length === 0) {
                console.error('❌ Error: El archivo evals/evals.json no tiene casos de prueba definidos.');
                errors++;
            }
            if (JSON.stringify(evalsJson).includes('nombre-de-la-skill')) {
                console.warn('⚠️ Advertencia: El archivo evals parece contener texto de marcador de posición (template).');
            }
        } catch (e) {
            console.error('❌ Error: evals/evals.json no es un JSON válido.');
            errors++;
        }
    }

    if (errors > 0) {
        console.log(`\n👎 Validación fallida: ${errors} error(es) encontrado(s).`);
        process.exit(1);
    } else {
        console.log(`\n✅ La skill en "${skillPath}" es válida y completa.`);
    }
}

validateSkill();
