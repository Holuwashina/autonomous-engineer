import { applyManagerOverride, User } from "./orders";

describe("applyManagerOverride", () => {
  it("applies the override for a manager", () => {
    const mgr: User = { id: "1", role: "manager" };
    expect(applyManagerOverride(100, 50, mgr)).toBe(50);
  });

  // The acceptance test that the T2 fix must satisfy: a non-manager is denied.
  it("rejects a non-manager (authorization enforced)", () => {
    const user: User = { id: "2", role: "user" };
    expect(() => applyManagerOverride(100, 50, user)).toThrow();
  });
});
