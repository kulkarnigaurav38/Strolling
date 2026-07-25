// Tiny runtime validators for the unauthenticated JSON API. Returns an error
// string (→ 400) or null. Kept dependency-free on purpose.

export function badString(
  v: unknown,
  field: string,
  { required = false, max = 120 }: { required?: boolean; max?: number } = {},
): string | null {
  if (v === undefined) return required ? `${field} is required` : null;
  if (typeof v !== "string" || v.trim().length === 0) {
    return `${field} must be a non-empty string`;
  }
  if (v.length > max) return `${field} must be at most ${max} characters`;
  return null;
}

export function badInt(
  v: unknown,
  field: string,
  { required = false, min = 0, max = 1_000_000 }: { required?: boolean; min?: number; max?: number } = {},
): string | null {
  if (v === undefined) return required ? `${field} is required` : null;
  if (typeof v !== "number" || !Number.isInteger(v) || v < min || v > max) {
    return `${field} must be an integer between ${min} and ${max}`;
  }
  return null;
}

export function badBool(v: unknown, field: string): string | null {
  if (v === undefined) return null;
  if (typeof v !== "boolean") return `${field} must be a boolean`;
  return null;
}
