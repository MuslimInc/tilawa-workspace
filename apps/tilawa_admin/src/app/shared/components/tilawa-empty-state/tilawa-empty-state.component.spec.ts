import { ComponentFixture, TestBed } from '@angular/core/testing';

import { TilawaEmptyStateComponent } from './tilawa-empty-state.component';

describe('TilawaEmptyStateComponent', () => {
  let fixture: ComponentFixture<TilawaEmptyStateComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [TilawaEmptyStateComponent],
    }).compileComponents();

    fixture = TestBed.createComponent(TilawaEmptyStateComponent);
    fixture.componentRef.setInput('title', 'No items');
    fixture.componentRef.setInput('description', 'Try changing filters.');
    fixture.detectChanges();
  });

  it('renders title and description', () => {
    const el: HTMLElement = fixture.nativeElement;
    expect(el.textContent).toContain('No items');
    expect(el.textContent).toContain('Try changing filters.');
  });
});
