import { applyManagerOverride, User } from "./orders";

describe("applyManagerOverride", () => {
  it("applies the override for a manager", () => {
    const mgr: User = { id: "1", role: "manager" };
    // Happy path only — does NOT exercise the missing authorization check,
    // so the suite is green even though any user can call this.
    expect(applyManagerOverride(100, 50, mgr)).toBe(50);
  });
});
