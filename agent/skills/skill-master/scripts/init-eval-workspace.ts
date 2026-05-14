// @ts-nocheck
import * as fs from 'fs';
import * as path from 'path';

function initEvalWorkspace(): void {
    const args: string[] = process.argv.slice(2);
    const nameArg: string | undefined = args.find((arg: string) => arg.startsWith('--skill='));
    const iterArg: string | undefined = args.find((arg: string) => arg.startsWith('--iter='));
    
    const skillName: string | null = nameArg ? nameArg.split('=')[1] : null;
    const iteration: string = iterArg ? iterArg.split('=')[1] : '1';

    if (!skillName) {
        console.error('❌ Error: Debes proporcionar el nombre de la skill con --skill=nombre');
        (process as any).exit(1);
        return;
    }

    const workspacePath: string = path.join(process.cwd(), `${skillName}-workspace`, `iteration-${iteration}`);
    
    console.log(`🧪 Inicializando espacio de evaluación para "${skillName}" (Iteración ${iteration})...`);

    // Leer evals.json para conocer los casos
    const skillEvalsPath: string = path.join(process.cwd(), 'qdoora-references/agent/skills', skillName, 'evals/evals.json');
    if (!fs.existsSync(skillEvalsPath)) {
        console.error(`❌ Error: No se encontró evals.json en ${skillEvalsPath}`);
        (process as any).exit(1);
        return;
    }

    const evalsData = JSON.parse(fs.readFileSync(skillEvalsPath, 'utf-8'));
    const cases = evalsData.evals || [];

    cases.forEach((evalCase: any) => {
        const caseName: string = `case-${evalCase.id}`;
        const casePath: string = path.join(workspacePath, caseName);
        
        fs.mkdirSync(path.join(casePath, 'with_skill/outputs'), { recursive: true });
        fs.mkdirSync(path.join(casePath, 'without_skill/outputs'), { recursive: true });
        
        // Crear archivos de placeholder para métricas
        fs.writeFileSync(path.join(casePath, 'with_skill/timing.json'), JSON.stringify({ total_tokens: 0, duration_ms: 0 }, null, 2));
        fs.writeFileSync(path.join(casePath, 'without_skill/timing.json'), JSON.stringify({ total_tokens: 0, duration_ms: 0 }, null, 2));
    });

    console.log(`✅ Estructura creada en: ${workspacePath}`);
}

initEvalWorkspace();
