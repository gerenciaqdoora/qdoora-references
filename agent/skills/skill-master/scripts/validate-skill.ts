// @ts-nocheck
import * as fs from 'fs';
import * as path from 'path';

function validateSkill(): void {
    const args: string[] = process.argv.slice(2);
    const pathArg: string | undefined = args.find((arg: string) => arg.startsWith('--path='));
    const skillPath: string | null = pathArg ? pathArg.split('=')[1] : null;

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

    const skillName = frontmatter.match(/name:\s*(.*)/)?.[1]?.trim();
    const folderName = path.basename(skillPath);

    if (skillName !== folderName) {
        console.warn(`⚠️ Advertencia: El nombre de la skill en el frontmatter ("${skillName}") no coincide con el nombre de la carpeta ("${folderName}").`);
    }

    console.log(`✅ La skill en "${skillPath}" es válida.`);
}

validateSkill();
