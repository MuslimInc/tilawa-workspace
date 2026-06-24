import { ComponentFixture, TestBed } from '@angular/core/testing';

import { TilawaErrorStateComponent } from './tilawa-error-state.component';

describe('TilawaErrorStateComponent', () => {
  let fixture: ComponentFixture<TilawaErrorStateComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [TilawaErrorStateComponent],
    }).compileComponents();

    fixture = TestBed.createComponent(TilawaErrorStateComponent);
    fixture.componentRef.setInput('message', 'Something failed');
    fixture.detectChanges();
  });

  it('renders alert with error message', () => {
    const el: HTMLElement = fixture.nativeElement;
    expect(el.querySelector('[role="alert"]')).toBeTruthy();
    expect(el.textContent).toContain('Something failed');
  });
});
