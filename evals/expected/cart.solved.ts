export interface LineItem {
  name: string;
  unitPrice: number; // in dollars, e.g. 19.99
  qty: number;
}

/** Sum of line items (unitPrice * qty). */
export function subtotal(items: LineItem[]): number {
  return items.reduce((sum, it) => sum + it.unitPrice * it.qty, 0);
}

/**
 * Apply a percentage discount to an amount and return the new amount.
 *
 * KNOWN BUG (the /selfcheck bug ticket targets this):
 * the result is not rounded to cents, so it can return fractional cents.
 * e.g. applyPercentDiscount(19.99, 10) returns 17.991, not 17.99.
 *
 * The existing test only covers a "clean" case (100 - 10% = 90) that hides
 * the bug, so the suite is green even though the function is wrong.
 */
export function applyPercentDiscount(amount: number, percent: number): number {
  const discounted = amount - amount * (percent / 100);
  // Round to cents to avoid fractional-cent results from floating-point math.
  return Math.round(discounted * 100) / 100;
}

/**
 * Apply a fixed-dollar discount to an amount and return the new amount.
 * Caps at 0 (never returns a negative total) and rounds to cents.
 * Added by the /selfcheck feature ticket.
 */
export function applyFixedDiscount(amount: number, off: number): number {
  const discounted = Math.max(0, amount - off);
  return Math.round(discounted * 100) / 100;
}
