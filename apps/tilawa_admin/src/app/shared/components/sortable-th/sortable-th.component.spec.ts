import { ComponentFixture, TestBed } from '@angular/core/testing';

import { SortableThComponent } from './sortable-th.component';

describe('SortableThComponent', () => {
  let fixture: ComponentFixture<SortableThComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [SortableThComponent],
    }).compileComponents();

    fixture = TestBed.createComponent(SortableThComponent);
    fixture.componentRef.setInput('label', 'Created');
    fixture.componentRef.setInput('field', 'createdAt');
    fixture.componentRef.setInput('sort', { field: 'createdAt', direction: 'asc' });
    fixture.detectChanges();
  });

  it('marks active column with aria-sort ascending', () => {
    const button = fixture.nativeElement.querySelector('button');
    expect(button.getAttribute('aria-sort')).toBe('ascending');
  });

  it('does not break table row layout', () => {
    const host = fixture.nativeElement as HTMLElement;
    expect(getComputedStyle(host).display).toBe('contents');
  });

  it('vertically centers header cell content', () => {
    const th = fixture.nativeElement.querySelector('th') as HTMLTableCellElement;
    expect(getComputedStyle(th).verticalAlign).toBe('middle');
  });

  it('keeps sort label on one line', () => {
    const label = fixture.nativeElement.querySelector('.tilawa-sort-btn') as HTMLElement;
    expect(getComputedStyle(label).whiteSpace).toBe('nowrap');
  });
});
