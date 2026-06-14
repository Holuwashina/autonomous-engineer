import { subtotal, applyPercentDiscount, LineItem } from "./cart";

// Acceptance oracle for AE-BUG-1 (rounding) only — does not reference the
// AE-FEAT-1 feature, so it can score a bug-only run.
describe("subtotal", () => {
  it("sums line items", () => {
    const items: LineItem[] = [
      { name: "A", unitPrice: 10, qty: 2 },
      { name: "B", unitPrice: 5, qty: 1 },
    ];
    expect(subtotal(items)).toBe(25);
  });
});

describe("applyPercentDiscount", () => {
  it("applies a clean percentage", () => {
    expect(applyPercentDiscount(100, 10)).toBe(90);
  });
  it("rounds the discounted amount to cents", () => {
    expect(applyPercentDiscount(19.99, 10)).toBe(17.99);
  });
});
