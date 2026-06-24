import { ComponentFixture, TestBed } from '@angular/core/testing';

import { TilawaAvatarComponent } from './tilawa-avatar.component';

describe('TilawaAvatarComponent', () => {
  let fixture: ComponentFixture<TilawaAvatarComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [TilawaAvatarComponent],
    }).compileComponents();

    fixture = TestBed.createComponent(TilawaAvatarComponent);
  });

  it('renders image when photo URL is present', () => {
    fixture.componentRef.setInput('displayName', 'Ahmed Ali');
    fixture.componentRef.setInput('photoUrl', 'https://example.com/photo.jpg');
    fixture.detectChanges();

    const img = fixture.nativeElement.querySelector('img');
    expect(img).toBeTruthy();
    expect(img.getAttribute('src')).toBe('https://example.com/photo.jpg');
    expect(img.getAttribute('aria-label')).toBe('Ahmed Ali');
    expect(fixture.nativeElement.querySelector('.tilawa-avatar-initials')).toBeNull();
  });

  it('renders initials when photo URL is missing', () => {
    fixture.componentRef.setInput('displayName', 'Sheikh Ahmed');
    fixture.componentRef.setInput('photoUrl', null);
    fixture.detectChanges();

    const initials = fixture.nativeElement.querySelector('.tilawa-avatar-initials');
    expect(initials).toBeTruthy();
    expect(initials.textContent.trim()).toBe('SA');
    expect(initials.getAttribute('aria-label')).toBe('Sheikh Ahmed');
    expect(fixture.nativeElement.querySelector('img')).toBeNull();
  });

  it('falls back to initials when image fails to load', () => {
    fixture.componentRef.setInput('displayName', 'Ahmed');
    fixture.componentRef.setInput('photoUrl', 'https://example.com/broken.jpg');
    fixture.detectChanges();

    const img = fixture.nativeElement.querySelector('img');
    expect(img).toBeTruthy();
    img.dispatchEvent(new Event('error'));
    fixture.detectChanges();

    const initials = fixture.nativeElement.querySelector('.tilawa-avatar-initials');
    expect(initials).toBeTruthy();
    expect(initials.textContent.trim()).toBe('A');
    expect(fixture.nativeElement.querySelector('img')).toBeNull();
  });

  it('uses email local-part initials when display name is empty', () => {
    fixture.componentRef.setInput('displayName', '');
    fixture.componentRef.setInput('email', 'sara@example.com');
    fixture.componentRef.setInput('photoUrl', null);
    fixture.detectChanges();

    const initials = fixture.nativeElement.querySelector('.tilawa-avatar-initials');
    expect(initials.textContent.trim()).toBe('s');
  });
});
