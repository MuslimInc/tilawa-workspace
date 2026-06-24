import { ComponentFixture, TestBed } from '@angular/core/testing';

import { TilawaStatusChipComponent } from './tilawa-status-chip.component';

describe('TilawaStatusChipComponent', () => {
  let fixture: ComponentFixture<TilawaStatusChipComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [TilawaStatusChipComponent],
    }).compileComponents();

    fixture = TestBed.createComponent(TilawaStatusChipComponent);
    fixture.componentRef.setInput('label', 'Pending');
    fixture.componentRef.setInput('status', 'pending');
    fixture.detectChanges();
  });

  it('renders label and warning variant for pending', () => {
    const chip = fixture.nativeElement.querySelector('span');
    expect(chip.textContent).toContain('Pending');
    expect(chip.getAttribute('data-variant')).toBe('warning');
  });
});
