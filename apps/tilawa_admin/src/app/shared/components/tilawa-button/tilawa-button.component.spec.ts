import { ComponentFixture, TestBed } from '@angular/core/testing';
import { provideRouter, Router } from '@angular/router';
import { vi } from 'vitest';

import { TilawaButtonComponent } from './tilawa-button.component';

describe('TilawaButtonComponent', () => {
  let fixture: ComponentFixture<TilawaButtonComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [TilawaButtonComponent],
      providers: [provideRouter([])],
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

  it('renders label for navigation link buttons', () => {
    fixture.componentRef.setInput('label', 'View');
    fixture.componentRef.setInput('link', ['/reports', '1']);
    fixture.detectChanges();
    const button = fixture.nativeElement.querySelector('button');
    expect(button.textContent).toContain('View');
  });

  it('navigates when link is set', () => {
    const router = TestBed.inject(Router);
    const navigateSpy = vi
      .spyOn(router, 'navigate')
      .mockResolvedValue(true);
    fixture.componentRef.setInput('label', 'View');
    fixture.componentRef.setInput('link', ['/reports', '1']);
    fixture.detectChanges();
    fixture.nativeElement.querySelector('button').click();
    expect(navigateSpy).toHaveBeenCalledWith(['/reports', '1']);
  });

  it('renders xs size', () => {
    fixture.componentRef.setInput('size', 'xs');
    fixture.detectChanges();
    const button = fixture.nativeElement.querySelector('button');
    expect(button.className).toContain('size-xs');
  });

  it('renders success variant', () => {
    fixture.componentRef.setInput('variant', 'success');
    fixture.detectChanges();
    const button = fixture.nativeElement.querySelector('button');
    expect(button.className).toContain('variant-success');
  });
});
