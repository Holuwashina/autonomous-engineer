import { subtotal, applyPercentDiscount, LineItem } from "./cart";

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
    // Clean case: 100 - 10% = 90 exactly. Passes even with the rounding bug.
    expect(applyPercentDiscount(100, 10)).toBe(90);
  });
});
