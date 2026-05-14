# Patrón de Limpieza RxJS y Estados de Carga

Evita memory leaks y centraliza la lógica de carga en `fuse-starter`.

```typescript
import { Subject, takeUntil, finalize } from 'rxjs';

export class MyComponent implements OnDestroy {
    private _unsubscribeAll: Subject<any> = new Subject<any>();
    public isLoading: boolean = false;

    save(): void {
        this.isLoading = true;
        
        this._service.update(data)
            .pipe(
                takeUntil(this._unsubscribeAll),
                finalize(() => {
                    this.isLoading = false;
                    this._changeDetectorRef.markForCheck();
                })
            )
            .subscribe({
                next: (res) => { ... },
                error: (err) => { ... }
            });
    }

    ngOnDestroy(): void {
        this._unsubscribeAll.next(null);
        this._unsubscribeAll.complete();
    }
}
```
