// @ts-nocheck
/**
 * Ejemplo de script agéntico:
 * 1. No interactivo.
 * 2. Soporta --help.
 * 3. Salida estructurada (JSON).
 */
function runExample() {
    const args = process.argv.slice(2);
    if (args.includes('--help')) {
        console.log('Uso: node example-script.js [opciones]');
        console.log('Opciones:');
        console.log('  --json    Retorna la salida en formato JSON');
        process.exit(0);
    }

    const data = {
        status: 'success',
        message: 'Hola desde el script de ejemplo',
        timestamp: new Date().toISOString()
    };

    if (args.includes('--json')) {
        console.log(JSON.stringify(data, null, 2));
    } else {
        console.log('✅ Script ejecutado correctamente.');
    }
}

runExample();
