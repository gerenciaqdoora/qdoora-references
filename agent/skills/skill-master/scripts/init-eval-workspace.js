const fs = require('fs');
const path = require('path');

function initEvalWorkspace() {
    const args = process.argv.slice(2);
    const nameArg = args.find(arg => arg.startsWith('--skill='));
    const iterArg = args.find(arg => arg.startsWith('--iter='));
    
    const skillName = nameArg ? nameArg.split('=')[1] : null;
    const iteration = iterArg ? iterArg.split('=')[1] : '1';

    if (!skillName) {
        console.error('❌ Error: Debes proporcionar el nombre de la skill con --skill=nombre');
        process.exit(1);
    }

    const workspacePath = path.join(process.cwd(), `${skillName}-workspace`, `iteration-${iteration}`);
    
    console.log(`🧪 Inicializando espacio de evaluación para "${skillName}" (Iteración ${iteration})...`);

    // Leer evals.json para conocer los casos
    const skillEvalsPath = path.join(process.cwd(), 'qdoora-references/agent/skills', skillName, 'evals/evals.json');
    if (!fs.existsSync(skillEvalsPath)) {
        console.error(`❌ Error: No se encontró evals.json en ${skillEvalsPath}`);
        process.exit(1);
    }

    const evalsData = JSON.parse(fs.readFileSync(skillEvalsPath, 'utf-8'));
    const cases = evalsData.evals || [];

    cases.forEach(evalCase => {
        const caseName = `case-${evalCase.id}`;
        const casePath = path.join(workspacePath, caseName);
        
        fs.mkdirSync(path.join(casePath, 'with_skill/outputs'), { recursive: true });
        fs.mkdirSync(path.join(casePath, 'without_skill/outputs'), { recursive: true });
        
        // Crear archivos de placeholder para métricas
        fs.writeFileSync(path.join(casePath, 'with_skill/timing.json'), JSON.stringify({ total_tokens: 0, duration_ms: 0 }, null, 2));
        fs.writeFileSync(path.join(casePath, 'without_skill/timing.json'), JSON.stringify({ total_tokens: 0, duration_ms: 0 }, null, 2));
    });

    console.log(`✅ Estructura creada en: ${workspacePath}`);
}

initEvalWorkspace();
