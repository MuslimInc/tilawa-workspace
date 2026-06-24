import { ComponentFixture, TestBed } from '@angular/core/testing';

import { TilawaButtonComponent } from './tilawa-button.component';

describe('TilawaButtonComponent', () => {
  let fixture: ComponentFixture<TilawaButtonComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [TilawaButtonComponent],
    }).compileComponents();

    fixture = TestBed.createComponent(TilawaButtonComponent);
    fixture.detectChanges();
  });

  it('renders primary variant by default', () => {
    const button = fixture.nativeElement.querySelector('button');
    expect(button.className).toContain('variant-primary');
  });

  it('disables button when loading', () => {
    fixture.componentRef.setInput('loading', true);
    fixture.detectChanges();
    const button = fixture.nativeElement.querySelector('button');
    expect(button.disabled).toBe(true);
  });

  it('shows spinner when loading', () => {
    fixture.componentRef.setInput('loading', true);
    fixture.detectChanges();
    const button = fixture.nativeElement.querySelector('button');
    const spinner = fixture.nativeElement.querySelector('.tilawa-btn-spinner');
    expect(spinner).toBeTruthy();
    expect(button.getAttribute('aria-busy')).toBe('true');
  });

  it('renders success variant', () => {
    fixture.componentRef.setInput('variant', 'success');
    fixture.detectChanges();
    const button = fixture.nativeElement.querySelector('button');
    expect(button.className).toContain('variant-success');
  });
});
