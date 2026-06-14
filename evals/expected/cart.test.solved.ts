import {
  subtotal,
  applyPercentDiscount,
  applyFixedDiscount,
  LineItem,
} from "./cart";

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

  // Regression test for the bug ticket: discounted totals must be rounded to cents.
  it("rounds the discounted amount to cents", () => {
    expect(applyPercentDiscount(19.99, 10)).toBe(17.99);
  });
});

describe("applyFixedDiscount", () => {
  it("subtracts a fixed dollar amount", () => {
    expect(applyFixedDiscount(50, 15)).toBe(35);
  });

  it("never returns a negative total (caps at 0)", () => {
    expect(applyFixedDiscount(10, 15)).toBe(0);
  });

  it("rounds to cents", () => {
    expect(applyFixedDiscount(19.999, 0)).toBe(20);
    expect(applyFixedDiscount(5.555, 1)).toBe(4.56);
  });
});
