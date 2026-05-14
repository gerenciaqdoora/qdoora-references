// @ts-nocheck
import * as fs from 'fs';
import * as path from 'path';

function scaffoldSkill(): void {
    const args: string[] = process.argv.slice(2);
    const nameArg: string | undefined = args.find((arg: string) => arg.startsWith('--name='));
    const name: string | null = nameArg ? nameArg.split('=')[1] : null;

    if (!name) {
        console.error('❌ Error: Debes proporcionar un nombre con --name=nombre-de-la-skill');
        (process as any).exit(1);
        return; // Guard clause for TS
    }

    const skillPath = path.join(__dirname, '../../', name);

    if (fs.existsSync(skillPath)) {
        console.error(`❌ Error: La skill "${name}" ya existe en ${skillPath}`);
        (process as any).exit(1);
        return;
    }

    console.log(`🏗️ Creando estructura para la skill: ${name}...`);

    const dirs: string[] = ['', 'scripts', 'references', 'assets', 'evals', 'evals/files'];
    dirs.forEach((dir: string) => {
        const dirPath: string = path.join(skillPath, dir);
        fs.mkdirSync(dirPath, { recursive: true });
    });

    // Copiar plantillas desde assets de skill-master
    const masterAssetsPath: string = path.join(__dirname, '../assets');
    
    // SKILL.md
    const skillTemplate: string = fs.readFileSync(path.join(masterAssetsPath, 'skill-template.md'), 'utf-8');
    fs.writeFileSync(path.join(skillPath, 'SKILL.md'), skillTemplate.replace(/nombre-de-la-skill/g, name as string));

    // evals.json
    const evalTemplate: string = fs.readFileSync(path.join(masterAssetsPath, 'eval-template.json'), 'utf-8');
    fs.writeFileSync(path.join(skillPath, 'evals/evals.json'), evalTemplate.replace(/nombre-de-la-skill/g, name as string));

    console.log(`✅ Skill "${name}" creada con éxito.`);
    console.log(`📍 Ruta: ${skillPath}`);
}

scaffoldSkill();
