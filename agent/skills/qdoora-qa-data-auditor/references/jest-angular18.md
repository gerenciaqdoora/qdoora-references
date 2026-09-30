# Jest — Estándares de Testing Angular 18 (Portal Cliente)

> Usa este archivo para tests del portal cliente `fuse-starter` (Angular 18 con RxJS y Modules).
> Framework: Jest + @angular/core/testing + HttpClientTestingModule

---

## Tabla de Contenidos
1. [Configuración Base](#1-configuración-base)
2. [Tests de Servicios (HttpClient)](#2-tests-de-servicios-httpclient)
3. [Tests de Componentes](#3-tests-de-componentes)
4. [Tests de Guards](#4-tests-de-guards)
5. [Tests de RxJS y Memory Leaks](#5-tests-de-rxjs-y-memory-leaks)
6. [Tests de Pipes Personalizados](#6-tests-de-pipes-personalizados)

---

## 1. Configuración Base

```typescript
// jest.config.ts (ya configurado en fuse-starter)
// Verificar que existe @angular-builders/jest o jest-preset-angular

// Comando de ejecución
// ng test                    → modo watch
// ng test --coverage         → con cobertura
// ng test --watchAll=false   → una sola ejecución (CI/CD)
```

```typescript
// Configuración mínima de TestBed en cada spec
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { HttpClientTestingModule, HttpTestingController } from '@angular/common/http/testing';
import { RouterTestingModule } from '@angular/router/testing';
import { NoopAnimationsModule } from '@angular/platform-browser/animations';
```

---

## 2. Tests de Servicios (HttpClient)

Los servicios de Angular 18 son la capa que consume la API. Testear que construyen las URLs
correctas, manejan errores del servidor y pasan los parámetros esperados es crítico.

```typescript
// src/app/modules/accounting/services/voucher.service.spec.ts
import { TestBed } from '@angular/core/testing';
import { HttpClientTestingModule, HttpTestingController } from '@angular/common/http/testing';
import { VoucherService } from './voucher.service';
import { environment } from 'environments/environment';

describe('VoucherService', () => {
    let service: VoucherService;
    let httpMock: HttpTestingController;
    const BASE = `${environment.apiUrl}/accounting/vouchers`;

    beforeEach(() => {
        TestBed.configureTestingModule({
            imports: [HttpClientTestingModule],
            providers: [VoucherService],
        });
        service = TestBed.inject(VoucherService);
        httpMock = TestBed.inject(HttpTestingController);
    });

    afterEach(() => httpMock.verify()); // ← crítico: verifica que no haya requests pendientes

    it('obtiene la lista de comprobantes con la company_id correcta', () => {
        const mockResponse = { data: [{ id: 'uuid-1', description: 'Pago' }] };

        service.getAll({ companyId: 'company-uuid' }).subscribe(res => {
            expect(res.data.length).toBe(1);
        });

        const req = httpMock.expectOne(`${BASE}?company_id=company-uuid`);
        expect(req.request.method).toBe('GET');
        req.flush(mockResponse);
    });

    it('maneja correctamente un error 422 del servidor', () => {
        const errorBody = { message: 'El comprobante está desbalanceado.' };

        service.create({ lines: [] }).subscribe({
            error: (err) => {
                expect(err.status).toBe(422);
                expect(err.error.message).toContain('desbalanceado');
            },
        });

        const req = httpMock.expectOne(BASE);
        req.flush(errorBody, { status: 422, statusText: 'Unprocessable Entity' });
    });

    it('adjunta el token Bearer en el header de Authorization', () => {
        service.getAll({ companyId: 'c1' }).subscribe();

        const req = httpMock.expectOne(`${BASE}?company_id=c1`);
        expect(req.request.headers.get('Authorization')).toMatch(/^Bearer /);
        req.flush({ data: [] });
    });
});
```

---

## 3. Tests de Componentes

```typescript
// src/app/modules/accounting/vouchers/voucher-list.component.spec.ts
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { VoucherListComponent } from './voucher-list.component';
import { VoucherService } from '../services/voucher.service';
import { of, throwError } from 'rxjs';

describe('VoucherListComponent', () => {
    let component: VoucherListComponent;
    let fixture: ComponentFixture<VoucherListComponent>;
    let voucherServiceSpy: jest.Mocked<VoucherService>;

    beforeEach(async () => {
        const spy = {
            getAll: jest.fn(),
        };

        await TestBed.configureTestingModule({
            imports: [VoucherListComponent], // Standalone Component
            providers: [{ provide: VoucherService, useValue: spy }],
        }).compileComponents();

        voucherServiceSpy = TestBed.inject(VoucherService) as jest.Mocked<VoucherService>;
        fixture = TestBed.createComponent(VoucherListComponent);
        component = fixture.componentInstance;
    });

    it('muestra los comprobantes cuando el servicio retorna datos', () => {
        voucherServiceSpy.getAll.mockReturnValue(of({
            data: [{ id: '1', description: 'Pago proveedor', amount: 100000 }],
        }));

        fixture.detectChanges(); // dispara ngOnInit

        const rows = fixture.nativeElement.querySelectorAll('[data-testid="voucher-row"]');
        expect(rows.length).toBe(1);
        expect(rows[0].textContent).toContain('Pago proveedor');
    });

    it('muestra app-shared-alert cuando el servicio falla', () => {
        voucherServiceSpy.getAll.mockReturnValue(
            throwError(() => ({ status: 500, error: { message: 'Error del servidor' } }))
        );

        fixture.detectChanges();

        const alert = fixture.nativeElement.querySelector('app-shared-alert');
        expect(alert).toBeTruthy(); // el componente compartido DEBE aparecer
    });

    it('establece isLoading en false después de la carga (via finalize)', () => {
        voucherServiceSpy.getAll.mockReturnValue(of({ data: [] }));
        fixture.detectChanges();
        expect(component.isLoading).toBe(false);
    });
});
```

---

## 4. Tests de Guards

```typescript
// src/app/core/guards/permission.guard.spec.ts
import { TestBed } from '@angular/core/testing';
import { Router } from '@angular/router';
import { permissionGuard } from './permission.guard';
import { AuthService } from '../services/auth.service';
import { of } from 'rxjs';

describe('permissionGuard', () => {
    let authServiceSpy: jest.Mocked<AuthService>;
    let routerSpy: jest.Mocked<Router>;

    beforeEach(() => {
        authServiceSpy = { checkPermission: jest.fn() } as any;
        routerSpy     = { navigate: jest.fn() } as any;

        TestBed.configureTestingModule({
            providers: [
                { provide: AuthService, useValue: authServiceSpy },
                { provide: Router, useValue: routerSpy },
            ],
        });
    });

    it('permite acceso cuando el backend confirma el permiso', (done) => {
        authServiceSpy.checkPermission.mockReturnValue(of(true));

        TestBed.runInInjectionContext(() => {
            const guard = permissionGuard('approve-liquidacion');
            (guard({} as any, {} as any) as any).subscribe((result: boolean) => {
                expect(result).toBe(true);
                expect(routerSpy.navigate).not.toHaveBeenCalled();
                done();
            });
        });
    });

    it('redirige a /unauthorized cuando el backend deniega el permiso', (done) => {
        authServiceSpy.checkPermission.mockReturnValue(of(false));

        TestBed.runInInjectionContext(() => {
            const guard = permissionGuard('approve-liquidacion');
            (guard({} as any, {} as any) as any).subscribe((result: boolean) => {
                expect(result).toBe(false);
                expect(routerSpy.navigate).toHaveBeenCalledWith(['/unauthorized']);
                done();
            });
        });
    });
});
```

---

## 5. Tests de RxJS y Memory Leaks

El patrón `takeUntil(this._unsubscribeAll)` + `finalize()` es obligatorio en componentes
complejos. Estos tests verifican que el patrón se implementó correctamente.

```typescript
// Verificación de que finalize() se ejecuta en destrucción del componente
it('llama a finalize y limpia el estado al destruir el componente', () => {
    voucherServiceSpy.getAll.mockReturnValue(of({ data: [] }));
    fixture.detectChanges();

    expect(component.isLoading).toBe(false); // finalize() se ejecutó

    // Simular destrucción
    fixture.destroy();

    // Verificar que el unsubscribe fue llamado (el subject se completó)
    expect(component['_unsubscribeAll'].isStopped).toBe(true);
});
```

---

## 6. Tests de Pipes Personalizados

```typescript
// src/app/shared/pipes/format-amount.pipe.spec.ts
import { FormatAmountPipe } from './format-amount.pipe';

describe('FormatAmountPipe', () => {
    let pipe: FormatAmountPipe;

    beforeEach(() => { pipe = new FormatAmountPipe(); });

    it('formatea un monto positivo en pesos chilenos', () => {
        expect(pipe.transform(1500000)).toBe('$1.500.000');
    });

    it('formatea un monto negativo con signo', () => {
        expect(pipe.transform(-50000)).toBe('-$50.000');
    });

    it('retorna "—" para valores nulos o undefined', () => {
        expect(pipe.transform(null)).toBe('—');
        expect(pipe.transform(undefined)).toBe('—');
    });
});
```
