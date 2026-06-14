import { applyFixedDiscount } from "./cart";

// Acceptance oracle for AE-FEAT-1 (fixed-amount discount) only.
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
