const fs = require('fs');
const path = require('path');

function scaffoldSkill() {
    const args = process.argv.slice(2);
    const nameArg = args.find(arg => arg.startsWith('--name='));
    const name = nameArg ? nameArg.split('=')[1] : null;

    if (!name) {
        console.error('❌ Error: Debes proporcionar un nombre con --name=nombre-de-la-skill');
        process.exit(1);
    }

    const skillPath = path.join(__dirname, '../../', name);

    if (fs.existsSync(skillPath)) {
        console.error(`❌ Error: La skill "${name}" ya existe en ${skillPath}`);
        process.exit(1);
    }

    console.log(`🏗️ Creando estructura para la skill: ${name}...`);

    const dirs = ['', 'scripts', 'references', 'assets', 'evals', 'evals/files'];
    dirs.forEach(dir => {
        const dirPath = path.join(skillPath, dir);
        fs.mkdirSync(dirPath, { recursive: true });
    });

    // Copiar plantillas desde assets de skill-master
    const masterAssetsPath = path.join(__dirname, '../assets');
    
    // SKILL.md
    const skillTemplate = fs.readFileSync(path.join(masterAssetsPath, 'skill-template.md'), 'utf-8');
    fs.writeFileSync(path.join(skillPath, 'SKILL.md'), skillTemplate.replace(/nombre-de-la-skill/g, name));

    // evals.json
    const evalTemplate = fs.readFileSync(path.join(masterAssetsPath, 'eval-template.json'), 'utf-8');
    fs.writeFileSync(path.join(skillPath, 'evals/evals.json'), evalTemplate.replace(/nombre-de-la-skill/g, name));

    console.log(`✅ Skill "${name}" creada con éxito.`);
    console.log(`📍 Ruta: ${skillPath}`);
}

scaffoldSkill();
