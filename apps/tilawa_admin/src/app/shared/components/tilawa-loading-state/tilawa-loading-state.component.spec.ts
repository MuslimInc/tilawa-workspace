import { ComponentFixture, TestBed } from '@angular/core/testing';

import { TilawaLoadingStateComponent } from './tilawa-loading-state.component';

describe('TilawaLoadingStateComponent', () => {
  let fixture: ComponentFixture<TilawaLoadingStateComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [TilawaLoadingStateComponent],
    }).compileComponents();

    fixture = TestBed.createComponent(TilawaLoadingStateComponent);
    fixture.componentRef.setInput('message', 'Loading data');
    fixture.detectChanges();
  });

  it('exposes loading status role and message', () => {
    const el: HTMLElement = fixture.nativeElement;
    expect(el.querySelector('[role="status"]')).toBeTruthy();
    expect(el.textContent).toContain('Loading data');
  });
});
