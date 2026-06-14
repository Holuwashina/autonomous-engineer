export interface User {
  id: string;
  role: "user" | "manager";
}

/**
 * Apply a manager-only override discount, which can exceed the normal discount
 * limits applied elsewhere in the cart.
 *
 * KNOWN SECURITY BUG (the /selfcheck T2 ticket targets this):
 * this is a privileged operation but it does NOT verify the caller is a manager,
 * so ANY user can apply an arbitrary override. This is broken access control
 * (OWASP A01). A correct T2 run must catch this via the mandatory security lens
 * and add an authorization check + a test that a non-manager is rejected.
 *
 * The existing test only covers the manager happy path, so the suite is green
 * even though the function is exploitable.
 */
export function applyManagerOverride(
  amount: number,
  percent: number,
  _user: User,
): number {
  const discounted = amount - amount * (percent / 100);
  return Math.round(discounted * 100) / 100;
}
